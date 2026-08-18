/**
 * Trace whether a Vue `provide`d value can be removed.
 *
 * Usage:
 *   node scripts/frontend/trace_provide_inject_usage.mjs <file|glob> [<file|glob>]
 *
 * Each matched file is traced: every top-level key the file `provide:`s is traced
 * (Vue inject resolves by top-level key, so nested object fields are not descended
 * into). Quote globs so the shell doesn't expand them. Files with a `provide:` get
 * the full per-key breakdown; files without one are skipped silently.
 *
 * Examples:
 *   node scripts/frontend/trace_provide_inject_usage.mjs \
 *     app/assets/javascripts/ci/pipeline_details/pipeline_header.js
 *   node scripts/frontend/trace_provide_inject_usage.mjs \
 *     'app/assets/javascripts/ci/**\/*.js'
 *
 * What it does (see doc/development/fe_guide/tooling.md for the workflow):
 *
 *   A) Static "definitely dead" check — if NO component/mixin anywhere injects
 *      the key (accounting for `inject: { local: { from: 'key' } }` aliasing and
 *      Composition-API `inject('key')`), the provide is unconditionally
 *      removable. This is sound: nothing can consume a key nobody injects.
 *
 * 
 *   B) Import-graph reachability — when injectors do exist, we ask whether any
 *      of them is reachable in the *module import graph* starting from the
 *      provider file (using dependency-cruiser, which resolves webpack aliases
 *      and follows dynamic `import()`). Because a component can only be rendered
 *      as a descendant if its module is importable from the root, import-graph
 *      UNREACHABILITY is a sound proof of "not a descendant" → removable.
 *      Reachability is only a *possibility* (shared barrels/utils can link
 *      unrelated components), so a reachable injector is reported as POSSIBLE
 *      and should be confirmed at runtime.
 *
 *   Soundness caveats (reported as INCONCLUSIVE boundaries): globally registered
 *   components (`Vue.component(...)`) and dependencies dependency-cruiser could
 *   not resolve (e.g. computed dynamic-import paths) break the "import ⟹
 *   reachable" guarantee.
 *
 *   `ee_else_ce`/`jh_else_ce`/`any_else_ce` aliases resolve to exactly one target
 *   per webpack config, but GitLab ships CE and EE builds from the same source —
 *   a module only reachable through the *other* edition's resolution is still
 *   live code. The reachability Breadth-First Search is therefore run once per
 *   available edition (CE always, EE when this checkout has one) and the
 *   results are unioned, so an edition-specific descendant isn't missed.
 *
 */
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { cruise } from 'dependency-cruiser';
// eslint-disable-next-line import/no-unresolved -- This is a valid subpath export
import extractWebpackResolveConfig from 'dependency-cruiser/config-utl/extract-webpack-resolve-config';
import babelParser from '@babel/parser';
import babelTraverse from '@babel/traverse';
import glob from 'glob';

const traverse = babelTraverse.default || babelTraverse;
const { parse } = babelParser;

const ROOT_PATH = path.resolve(import.meta.dirname, '../../');

// EE and JH ship their frontend as optional source overlays that are absent on FOSS
// checkouts (filtered out below). Centralised here so these paths live in exactly one
// place and the rest of the script just works against "whatever roots exist".
const ASSET_ROOTS = ['app/assets/javascripts', 'ee/app/assets/javascripts', 'jh/app/assets/javascripts'];
const SEARCH_DIRS = ASSET_ROOTS.filter((dir) => fs.existsSync(path.join(ROOT_PATH, dir)));
const HAS_EE = SEARCH_DIRS.includes('ee/app/assets/javascripts');
const HAS_JH = HAS_EE && SEARCH_DIRS.includes('jh/app/assets/javascripts'); // mirrors config/helpers/is_jh_env.js

/**
 * `config/webpack.config.js` uses `NormalModuleReplacementPlugin` (not `resolve.alias`) to
 * collapse `ee_component/*.vue`, `jh_component/*.vue`, and `jh_else_ee/*.vue` imports to a
 * no-op stub whenever the corresponding edition isn't part of the build. dependency-cruiser
 * only sees `resolve` (via `extractWebpackResolveConfig`), not webpack plugins, so without
 * this it would report those as unresolved boundaries even though the real build resolves
 * them fine — to nothing. Mirrors the plugin's own `!IS_EE`/`!IS_JH` conditions.
 * @param {boolean} isEE
 * @param {boolean} isJH
 * @returns {RegExp[]}
 */
function emptyComponentStubPatterns(isEE, isJH) {
  const patterns = [];
  if (!isEE) patterns.push(/^ee_component\//);
  if (!isJH) patterns.push(/^jh_component\//);
  if (!isEE && !isJH) patterns.push(/^jh_else_ee\//);
  return patterns;
}

const BABEL_PLUGINS = [
  'jsx',
  'dynamicImport',
  'classProperties',
  'classPrivateProperties',
  'classPrivateMethods',
  'objectRestSpread',
  'optionalChaining',
  'nullishCoalescingOperator',
  'importAssertions',
  'topLevelAwait',
  'decorators-legacy',
];

/**
 * Normalise a path to a repo-relative POSIX string (how dependency-cruiser keys modules).
 * @param {string} filePath
 * @returns {string}
 */
function toRepoRelative(filePath) {
  const abs = path.isAbsolute(filePath) ? filePath : path.resolve(ROOT_PATH, filePath);
  return path.relative(ROOT_PATH, abs).split(path.sep).join('/');
}

/**
 * Compact a repo-relative module path for display: drop the asset-root prefix
 * (tagging EE/JH with an `ee:`/`jh:` marker) and elide deep middle segments.
 * @param {string} repoRel
 * @returns {string}
 */
function shortPath(repoRel) {
  let marker = '';
  let rest = repoRel;
  for (const [prefix, label] of [
    ['ee/app/assets/javascripts/', 'ee/'],
    ['jh/app/assets/javascripts/', 'jh/'],
    ['app/assets/javascripts/', '~/'],
  ]) {
    if (repoRel.startsWith(prefix)) {
      marker = label;
      rest = repoRel.slice(prefix.length);
      break;
    }
  }
  return `${marker}${rest}`;
}

/**
 * Pull the contents of every `<script>` block out of an SFC (or return the file as-is for .js).
 * @param {string} filePath
 * @param {string} source
 * @returns {string}
 */
function extractScript(filePath, source) {
  if (!filePath.endsWith('.vue')) return source;
  const blocks = [...source.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/gi)];
  return blocks.map((m) => m[1]).join('\n');
}

/**
 * Resolve the provided name an inject entry maps to, honouring `{ from: 'x' }` aliasing.
 * @param {import('@babel/types').ObjectProperty} property
 * @returns {string}
 */
function providedNameFromInjectEntry(property) {
  const localName =
    property.key.type === 'Identifier' ? property.key.name : property.key.value;
  if (property.value && property.value.type === 'ObjectExpression') {
    const fromProp = property.value.properties.find(
      (p) => p.type === 'ObjectProperty' && !p.computed && p.key.name === 'from',
    );
    if (fromProp && fromProp.value.type === 'StringLiteral') {
      return fromProp.value.value;
    }
  }
  return localName;
}

/**
 * Return true if the parsed module injects `key` (options API or `inject('key')`).
 * @param {import('@babel/types').File} ast
 * @param {string} key
 * @returns {boolean}
 */
function moduleInjectsKey(ast, key) {
  let injects = false;

  traverse(ast, {
    // Options API: `inject: [...]` / `inject: { ... }`
    ObjectProperty(p) {
      const { node } = p;
      if (node.computed || !node.key || node.key.name !== 'inject') return;

      const { value } = node;
      if (value.type === 'ArrayExpression') {
        injects ||= value.elements.some(
          (el) => el && el.type === 'StringLiteral' && el.value === key,
        );
      } else if (value.type === 'ObjectExpression') {
        injects ||= value.properties.some(
          (prop) => prop.type === 'ObjectProperty' && providedNameFromInjectEntry(prop) === key,
        );
      }
    },
    // Composition API: `inject('key')`
    CallExpression(p) {
      const { callee, arguments: args } = p.node;
      if (
        callee.type === 'Identifier' &&
        callee.name === 'inject' &&
        args[0] &&
        args[0].type === 'StringLiteral' &&
        args[0].value === key
      ) {
        injects = true;
      }
    },
  });

  return injects;
}

/** Memoise injector lookups: the same key is often traced across multiple provider files. */
const injectorCache = new Map();

/**
 * Technique A: every module that injects `key`.
 * @param {string} key
 * @returns {{ injectors: string[], scanned: number, parseFailures: number }}
 */
function findInjectorModules(key) {
  if (injectorCache.has(key)) return injectorCache.get(key);

  let candidates = [];
  try {
    const out = execFileSync(
      'rg',
      ['-l', '--glob', '*.{vue,js}', '-F', key, ...SEARCH_DIRS],
      { cwd: ROOT_PATH, encoding: 'utf-8', maxBuffer: 64 * 1024 * 1024 },
    );
    candidates = out.split('\n').filter(Boolean);
  } catch (e) {
    if (e.code === 'ENOENT') {
      throw new Error(
        'ripgrep (rg) not found. Install it: https://github.com/BurntSushi/ripgrep#installation',
      );
    }
    // rg exits 1 when there are no matches — that just means no injectors.
    if (e.status !== 1) throw e;
  }

  const injectors = [];
  let parseFailures = 0;

  for (const file of candidates) {
    const source = fs.readFileSync(path.join(ROOT_PATH, file), 'utf-8');
    const script = extractScript(file, source);
    if (!script.includes('inject')) continue;

    try {
      const ast = parse(script, { sourceType: 'module', plugins: BABEL_PLUGINS });
      if (moduleInjectsKey(ast, key)) injectors.push(toRepoRelative(file));
    } catch {
      parseFailures += 1;
    }
  }

  const result = { injectors, scanned: candidates.length, parseFailures };
  injectorCache.set(key, result);
  return result;
}

/**
 * Technique B: Breadth-First Search the import graph from `providerFile` to the injectors.
 *
 * dependency-cruiser only deep-parses a `.vue` SFC's `<script>` when the file is
 * scanned as an *entry*, not when it is merely *followed* (followed `.vue` come
 * back as dependency-less leaves, which would hide the whole component tree). So
 * we cruise iteratively: each Breadth-First Search level re-cruises the newly discovered modules
 * as entries, guaranteeing every `.vue` on the frontier gets parsed. The full
 * subtree is explored once and reused for every provide key.
 *
 * The Breadth-First Search is seeded with the provider AND any sibling/ancestor router module (see
 * `findRouterModules`), so components rendered only via `<router-view>` are reached.
 */
let resolveOptionsPromise;
/**
 * Lazily load (and memoise) the webpack resolve config dependency-cruiser needs,
 * for whichever edition this checkout is (CE if there's no `ee/`, EE otherwise).
 * @returns {Promise<object>}
 */
function getResolveOptions() {
  // Loading the webpack config is slow; do it once even when iterating many files.
  resolveOptionsPromise ||= extractWebpackResolveConfig('./config/webpack.config.js');
  return resolveOptionsPromise;
}

let ceResolveOptionsPromise;
const CE_RESOLVE_CONFIG_MARKER = '<<<CE_RESOLVE_CONFIG>>>';

/**
 * Lazily load (and memoise) the webpack resolve config with `ee_else_ce`/`any_else_ce`
 * forced to their CE targets, regardless of which edition this checkout is.
 *
 * `config/helpers/aliases.js` bakes `IS_EE` into `require.cache`d modules the moment
 * it's first loaded, so re-requiring it in-process with a different `FOSS_ONLY` env
 * var has no effect — the cached module wins. A child process starts that cache
 * fresh, so it's the only reliable way to get the *other* edition's alias map.
 * @returns {Promise<object>}
 */
function getCeResolveOptions() {
  ceResolveOptionsPromise ||= (async () => {
    const helperPath = path.join(ROOT_PATH, 'tmp/depcruise-trace-ce-resolve-config.mjs');
    fs.mkdirSync(path.dirname(helperPath), { recursive: true });
    fs.writeFileSync(
      helperPath,
      "import extractWebpackResolveConfig from 'dependency-cruiser/config-utl/extract-webpack-resolve-config';\n" +
        "const options = await extractWebpackResolveConfig('./config/webpack.config.js');\n" +
        // Loading the webpack config prints its own banner lines to stdout (Vue
        // version, incremental-compiler status); a marker lets us pull the JSON
        // back out regardless of whatever else lands on stdout around it.
        `process.stdout.write('${CE_RESOLVE_CONFIG_MARKER}' + JSON.stringify(options));\n`,
    );
    const out = execFileSync('node', [helperPath], {
      cwd: ROOT_PATH,
      encoding: 'utf-8',
      env: { ...process.env, FOSS_ONLY: 'true' },
      maxBuffer: 16 * 1024 * 1024,
    });
    return JSON.parse(out.slice(out.indexOf(CE_RESOLVE_CONFIG_MARKER) + CE_RESOLVE_CONFIG_MARKER.length));
  })();
  return ceResolveOptionsPromise;
}

/**
 * The CE path plus any EE/JH mirror of it that exists on disk.
 * @param {string} repoRel
 * @returns {string[]}
 */
function ceEeJhVariants(repoRel) {
  const roots = ASSET_ROOTS.map((root) => `${root}/`);
  const base = roots.find((root) => repoRel.startsWith(root));
  if (!base) return [repoRel];
  const rest = repoRel.slice(base.length);
  return roots
    .map((root) => `${root}${rest}`)
    .filter((candidate) => fs.existsSync(path.join(ROOT_PATH, candidate)));
}

/**
 * A provider often renders its descendants through `<router-view>`, where the routes
 * live in a sibling/ancestor `routes`/`router` module the provider does not import
 * directly (the router is built by the bundle and passed in, or registered elsewhere).
 * Those route components are real descendants but invisible to an import graph rooted at
 * the provider. Walk up from the provider's directory and return any `routes`/`router`
 * module (plus its EE/JH mirror) so the reachability Breadth-First Search can seed them.
 * @param {string} providerRel
 * @returns {string[]}
 */
function findRouterModules(providerRel) {
  const found = new Set();
  let dir = path.dirname(path.join(ROOT_PATH, providerRel));

  for (let level = 0; level < 6; level += 1) {
    for (const base of ['routes', 'router']) {
      for (const candidate of [`${base}.js`, `${base}.mjs`, `${base}/index.js`, `${base}/index.mjs`]) {
        const abs = path.join(dir, candidate);
        if (fs.existsSync(abs)) {
          ceEeJhVariants(toRepoRelative(abs)).forEach((variant) => found.add(variant));
        }
      }
    }
    if (path.basename(dir) === 'javascripts') break; // don't climb past the asset root
    const up = path.dirname(dir);
    if (up === dir) break;
    dir = up;
  }
  return [...found];
}

/**
 * Run one Breadth-First Search over the import graph, resolved per `edition`.
 * Factored out of `buildReachability` so it can be run once per edition (see below).
 * @param {string[]} seeds
 * @param {{ resolveOptions: object, cacheFolder: string, stubPatterns: RegExp[] }} edition
 *   `stubPatterns`: unresolved imports matching these are a real, empty stub in this
 *   edition's build (see `emptyComponentStubPatterns`), not a boundary
 * @returns {Promise<{ reachable: Map<string, string|null>, boundaries: string[] }>}
 */
async function traverseImportGraph(seeds, { resolveOptions, cacheFolder, stubPatterns }) {
  const cruiseOptions = {
    doNotFollow: { path: 'node_modules' },
    exclude: { path: 'node_modules' }, // NB: do NOT exclude dynamic imports
    moduleSystems: ['es6', 'cjs', 'amd'],
    enhancedResolveOptions: { extensions: ['.js', '.cjs', '.mjs', '.vue'] },
    cache: { folder: cacheFolder, strategy: 'metadata' },
  };

  const parent = new Map(seeds.map((seed) => [seed, null])); // resolved module -> parent (Breadth-First Search tree)
  const boundaries = [];
  const cruised = new Set();
  let frontier = [...seeds];

  while (frontier.length) {
    const batch = frontier.filter((file) => !cruised.has(file));
    batch.forEach((file) => cruised.add(file));
    if (batch.length === 0) break;

    // Cruise the frontier as entries so `.vue` scripts on it are actually parsed.
    // Sequential by design: each Breadth-First Search level depends on the previous level's results.
    // eslint-disable-next-line no-await-in-loop
    const { output } = await cruise(batch, cruiseOptions, resolveOptions);
    const bySource = new Map(output.modules.map((m) => [m.source, m]));

    const next = [];
    for (const file of batch) {
      const mod = bySource.get(file);
      if (!mod) continue;

      // Globally registered components escape the "import ⟹ renderable" guarantee.
      if (/\bVue\.component\s*\(/.test(fs.readFileSync(path.join(ROOT_PATH, file), 'utf-8'))) {
        boundaries.push(`global component registration in ${file}`);
      }

      for (const dep of mod.dependencies) {
        if (dep.couldNotResolve) {
          if (stubPatterns.some((pattern) => pattern.test(dep.module))) continue;
          boundaries.push(`unresolved import in ${file} → "${dep.module}"`);
          continue;
        }
        if (!parent.has(dep.resolved)) {
          parent.set(dep.resolved, file);
          next.push(dep.resolved);
        }
      }
    }

    frontier = next;
  }

  return { reachable: parent, boundaries };
}

/**
 * Build the import-graph reachability set for one provider (see the Technique B block above).
 *
 * Run once per available edition (CE always; EE too when this checkout has an `ee/`
 * overlay) and union the results, since an `ee_else_ce`/`any_else_ce` import resolves
 * to a different file per edition and both are real, shipped code.
 * @param {string} providerRel
 * @returns {Promise<{ reachable: Map<string, string|null>, boundaries: string[], moduleCount: number }>}
 */
async function buildReachability(providerRel) {
  // Seed the provider plus any sibling/ancestor router module, so descendants that
  // are only reachable through `<router-view>` are counted as reachable.
  const routerModules = findRouterModules(providerRel);
  if (routerModules.length > 0) {
    console.log(`Including router module(s): ${routerModules.join(', ')}`);
  }
  const seeds = [providerRel, ...routerModules];

  const editions = [
    traverseImportGraph(seeds, {
      resolveOptions: await getResolveOptions(),
      cacheFolder: './tmp/cache/depcruise-trace-cache',
      stubPatterns: emptyComponentStubPatterns(HAS_EE, HAS_JH),
    }),
  ];
  // A provider that itself lives under ee/ (or jh/) never ships in a CE build at
  // all, so it has no separate CE edition to check — its own bare `ee/...` imports
  // are normal EE-only code, not a CE-resolution gap. Only run the second pass for
  // providers that are actually part of the CE-buildable tree.
  if (HAS_EE && providerRel.startsWith('app/assets/javascripts/')) {
    editions.push(
      traverseImportGraph(seeds, {
        resolveOptions: await getCeResolveOptions(),
        cacheFolder: './tmp/cache/depcruise-trace-cache-ce',
        stubPatterns: emptyComponentStubPatterns(false, false),
      }),
    );
  }
  const results = await Promise.all(editions);

  const reachable = new Map();
  const boundaries = [];
  for (const result of results) {
    for (const [module, parentModule] of result.reachable) {
      if (!reachable.has(module)) reachable.set(module, parentModule);
    }
    boundaries.push(...result.boundaries);
  }

  return { reachable, boundaries, moduleCount: reachable.size };
}

/**
 * Walk the BFS parent chain from a seed down to `module`, inclusive of both ends.
 * `chain.length - 1` is the hop-count (depth) from the seed to `module`.
 * @param {Map<string, string|null>} parent
 * @param {string} module
 * @returns {string[]}
 */
function chainFromSeed(parent, module) {
  const chain = [module];
  let current = module;
  while (parent.get(current)) {
    current = parent.get(current);
    chain.unshift(current);
  }
  return chain;
}

/**
 * Collect the static key names of an ObjectExpression; flag spreads/computed keys as opaque.
 * @param {import('@babel/types').ObjectExpression} objectExpression
 * @returns {{ names: string[], opaque: boolean }}
 */
function objectKeyNames(objectExpression) {
  const names = [];
  let opaque = false;
  for (const prop of objectExpression.properties) {
    if (prop.type !== 'ObjectProperty' && prop.type !== 'ObjectMethod') {
      opaque = true; // SpreadElement
      continue;
    }
    if (prop.computed) {
      opaque = true; // computed key, e.g. `{ [name]: … }`
      continue;
    }
    names.push(prop.key.type === 'Identifier' ? prop.key.name : prop.key.value);
  }
  return { names, opaque };
}

/**
 * Get the object literal a `provide()` function returns (handles arrow shorthand + `return {…}`).
 * @param {import('@babel/types').ArrowFunctionExpression | import('@babel/types').FunctionExpression | import('@babel/types').ObjectMethod} fnNode
 * @returns {import('@babel/types').ObjectExpression | null}
 */
function returnedObject(fnNode) {
  if (fnNode.type === 'ArrowFunctionExpression' && fnNode.body.type === 'ObjectExpression') {
    return fnNode.body;
  }
  const body = fnNode.body && fnNode.body.type === 'BlockStatement' ? fnNode.body.body : [];
  const ret = body.find(
    (s) => s.type === 'ReturnStatement' && s.argument && s.argument.type === 'ObjectExpression',
  );
  return ret ? ret.argument : null;
}

/**
 * Extract the top-level provide keys declared in a file. Vue inject resolves by
 * top-level key only, so nested object fields are deliberately not descended into.
 * @param {string} providerRel
 * @returns {{ keys: string[], found: boolean, opaque: boolean, parseError?: string }}
 */
function extractProvideKeys(providerRel) {
  const source = fs.readFileSync(path.join(ROOT_PATH, providerRel), 'utf-8');

  let ast;
  try {
    ast = parse(extractScript(providerRel, source), { sourceType: 'module', plugins: BABEL_PLUGINS });
  } catch (error) {
    return { keys: [], found: false, opaque: false, parseError: error.message };
  }

  const keys = new Set();
  let found = false;
  let opaque = false;

  const ingest = (objectExpression) => {
    if (!objectExpression) {
      opaque = true; // provide is a function/identifier we can't statically read
      return;
    }
    const { names, opaque: o } = objectKeyNames(objectExpression);
    names.forEach((n) => keys.add(n));
    opaque ||= o;
  };

  traverse(ast, {
    'ObjectProperty|ObjectMethod': function visitProvide(p) {
      const { node } = p;
      if (node.computed || !node.key || node.key.name !== 'provide') return;
      found = true;
      if (node.type === 'ObjectMethod') ingest(returnedObject(node));
      else if (node.value.type === 'ObjectExpression') ingest(node.value);
      else if (
        node.value.type === 'ArrowFunctionExpression' ||
        node.value.type === 'FunctionExpression'
      ) {
        ingest(returnedObject(node.value));
      } else {
        opaque = true; // `provide: someVariable`
      }
    },
  });

  return { keys: [...keys], found, opaque };
}

// Opaque verdict tokens; the human-readable text lives in SECTION_LABEL / SHORT.
const VERDICT = {
  REMOVABLE: 'REMOVABLE',
  LIKELY_REMOVABLE: 'LIKELY_REMOVABLE',
  IN_USE: 'IN_USE',
  INCONCLUSIVE: 'INCONCLUSIVE',
};

const SHORT = {
  [VERDICT.REMOVABLE]: 'REMOVABLE',
  [VERDICT.LIKELY_REMOVABLE]: 'LIKELY-REMOVABLE',
  [VERDICT.IN_USE]: 'IN USE',
  [VERDICT.INCONCLUSIVE]: 'INCONCLUSIVE',
};

// Descriptive headings for the per-file verdict sections.
const SECTION_LABEL = {
  [VERDICT.REMOVABLE]: '⚠️  REMOVABLE: Injected nowhere',
  [VERDICT.LIKELY_REMOVABLE]: '⚠️  LIKELY REMOVABLE: No injector reachable',
  [VERDICT.IN_USE]: '✅ IN USE: Injector reachable',
  [VERDICT.INCONCLUSIVE]: '❓ INCONCLUSIVE: Dynamic boundary',
};

// Surface the actionable (dead) verdicts first within each file.
const VERDICT_ORDER = [
  VERDICT.REMOVABLE,
  VERDICT.LIKELY_REMOVABLE,
  VERDICT.INCONCLUSIVE,
  VERDICT.IN_USE,
];

/**
 * Trace one provider file. Files with a `provide:` get the full per-key breakdown
 * (injector locations + dep chains); files with nothing to trace are skipped silently.
 * @param {string} providerRel
 * @returns {Promise<{ rows: Array<{ file: string, key: string, verdict: string }>, status: 'traced'|'skipped' }>}
 */
async function traceFile(providerRel) {
  const result = extractProvideKeys(providerRel);
  // No `provide:` (or unparseable) → nothing to trace, skip silently.
  if (result.parseError || !result.found) {
    return { rows: [], status: 'skipped' };
  }
  // Has a `provide:`, but every key is dynamic/spread — say so rather than
  // pretending there was no provide block.
  if (result.keys.length === 0) {
    console.log(
      `· ${providerRel} — provide: has only dynamic/spread keys; cannot statically analyse`,
    );
    return { rows: [], status: 'skipped' };
  }
  const { keys, opaque } = result;

  // Level 1: announce the file up front — the analysis below can take a while
  // (import-graph cruise), so printing now stops the script looking like it hung.
  console.log(
    `\n${'─'.repeat(80)}\n${providerRel} — ${keys.length} keys` +
      `${opaque ? ' [partial: spread/computed provide]' : ''}`,
  );

  // Technique A — injectors per key (cheap, memoized, AST-based).
  const perKey = keys.map((key) => ({ key, ...findInjectorModules(key) }));

  // Technique B — build the import graph once and reuse it for every key in this file.
  let reachable = new Map();
  let boundaries = [];
  if (perKey.some((k) => k.injectors.length > 0)) {
    ({ reachable, boundaries } = await buildReachability(providerRel));
    console.log(`  · ${reachable.size} modules reached`);
  }

  const classified = perKey.map(({ key, injectors }) => {
    const reachableInjectors = injectors.filter((m) => reachable.has(m));
    let verdict;
    if (injectors.length === 0) verdict = VERDICT.REMOVABLE;
    else if (reachableInjectors.length > 0) verdict = VERDICT.IN_USE;
    else if (boundaries.length > 0) verdict = VERDICT.INCONCLUSIVE;
    else verdict = VERDICT.LIKELY_REMOVABLE;
    return { key, injectors, reachableInjectors, verdict };
  });

  // Group keys under their verdict so each section can be scanned at a glance.
  const groups = new Map(VERDICT_ORDER.map((verdict) => [verdict, []]));
  classified.forEach((entry) => groups.get(entry.verdict).push(entry));

  for (const verdict of VERDICT_ORDER) {
    const entries = groups.get(verdict);
    if (entries.length === 0) continue;
    console.log(`\n  ${SECTION_LABEL[verdict]} (${entries.length})`);

    for (const { key, injectors, reachableInjectors } of entries) {
      if (verdict === VERDICT.REMOVABLE) {
        console.log(`    ${key}`);
        continue;
      }
      const list = verdict === VERDICT.IN_USE ? reachableInjectors : injectors;
      const label = verdict === VERDICT.IN_USE ? 'usages' : 'unrelated usages';
      console.log(`    ${key} (${list.length} ${label})`);
      list.forEach((m) => {
        if (verdict !== VERDICT.IN_USE) {
          console.log(`      ← ${shortPath(m)}`);
          return;
        }
        const chain = chainFromSeed(reachable, m);
        const depth = chain.length - 1;
        console.log(`      ← ${shortPath(chain[0])}`);
        chain.slice(1).forEach((file, i) => {
          const isLast = i === chain.length - 2;
          console.log(`        → ${shortPath(file)}${isLast ? `  (depth ${depth})` : ''}`);
        });
      });
    }
  }

  if (boundaries.length > 0) {
    console.log('\n  ❓ dynamic boundaries (limit soundness of removable verdicts):');
    [...new Set(boundaries)].slice(0, 10).forEach((b) => console.log(`       ${b}`));
  }

  const rows = classified.map(({ key, verdict }) => ({ file: providerRel, key, verdict }));
  return { rows, status: 'traced' };
}

/**
 * Expand the CLI patterns (literal paths or globs) into a deduped list of `.vue`/`.js` files.
 * @param {string[]} patterns
 * @returns {string[]}
 */
function expandFiles(patterns) {
  const files = new Set();
  for (const pattern of patterns) {
    const asFile = path.join(ROOT_PATH, pattern);
    const matches =
      fs.existsSync(asFile) && fs.statSync(asFile).isFile()
        ? [pattern]
        : glob.sync(pattern, { cwd: ROOT_PATH });
    // Only Vue components and JS modules are parseable; skip .graphql, .json, etc.
    for (const match of matches) {
      if (/\.(vue|js)$/.test(match)) files.add(toRepoRelative(match));
    }
  }
  return [...files].sort();
}

async function main() {
  const patterns = process.argv.slice(2);

  if (patterns.length === 0) {
    console.error('Usage: node scripts/frontend/trace_provide_inject_usage.mjs <file|glob> [<file|glob>…]');
    process.exitCode = 1;
    return;
  }

  const files = expandFiles(patterns);
  if (files.length === 0) {
    console.error('No matching .vue/.js files.');
    process.exitCode = 1;
    return;
  }
  console.log(`Tracing ${files.length} file(s)…`);

  const allRows = [];
  for (const file of files) {
    // eslint-disable-next-line no-await-in-loop
    const { rows } = await traceFile(file);
    allRows.push(...rows);
  }

  // Cross-file roundup of the actionable verdicts.
  const candidates = allRows.filter(
    ({ verdict }) => verdict === VERDICT.REMOVABLE || verdict === VERDICT.LIKELY_REMOVABLE,
  );
  console.log(`\n${'='.repeat(80)}\nRemoval candidates (${candidates.length}):`);
  if (candidates.length === 0) {
    console.log('  none — every provided key is in use or inconclusive.');
  } else {
    // Group the candidates under their provider file.
    const byFile = new Map();
    for (const candidate of candidates) {
      if (!byFile.has(candidate.file)) byFile.set(candidate.file, []);
      byFile.get(candidate.file).push(candidate);
    }
    for (const [file, items] of byFile) {
      console.log(`${file}:`);
      // REMOVABLE before LIKELY-REMOVABLE so the surest wins read first.
      items.sort((a, b) => VERDICT_ORDER.indexOf(a.verdict) - VERDICT_ORDER.indexOf(b.verdict));
      items.forEach(({ key, verdict }) =>
        console.log(`  ${SHORT[verdict].padEnd(16)} ${key}`),
      );
    }
  }
  console.log(
    '\nIN USE = possible descent (confirm at runtime); it is not proof of use.' +
      '\nDepth = import-graph hops from provider to injector — a large depth means more indirection to verify by hand.',
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
