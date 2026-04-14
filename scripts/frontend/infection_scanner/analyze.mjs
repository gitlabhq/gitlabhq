/**
 * Core infection analysis logic, separated from CLI/UI harness for testability.
 *
 * Usage:
 *   import { analyze, detectAppRoot } from './analyze.mjs';
 *   const result = await analyze({ rootPath, entrypoints, infectionSpecifiers, aliasMap });
 */
import { isBuiltin } from 'node:module';
import path from 'node:path';
import fs from 'node:fs';
import { readFile } from 'node:fs/promises';
import { init, parse } from 'es-module-lexer';

const EXTENSIONS = ['.mjs', '.js'];
const CONCURRENCY = 64;

/**
 * Create a module resolver that handles aliases, file extensions, index files,
 * and node_modules with pkg.exports (Vite-style) and pkg.module (webpack-style).
 *
 * @param {Object} options
 * @param {Object<string, string>} [options.aliasMap] - Webpack-style alias map.
 *   Keys ending with `$` are exact matches; others are prefix matches.
 * @param {string} options.rootPath - Project root for node_modules lookup.
 * @param {Function} [options.fallbackResolve] - Optional fallback resolver function.
 *   Called with (specifier, fromDir) when standard resolution fails. Should return
 *   an absolute path or null.
 * @returns {{ resolveModule: (specifier: string, fromFile: string) => string|null, resolveModuleAll: (specifier: string, fromFile: string) => string[]|null, tryFile: (p: string) => boolean }}
 */
export function createResolver({ aliasMap = {}, rootPath, fallbackResolve }) {
  const sortedAliasKeys = Object.keys(aliasMap).sort((a, b) => {
    const aExact = a.endsWith('$');
    const bExact = b.endsWith('$');
    if (aExact !== bExact) return aExact ? -1 : 1;
    return b.length - a.length;
  });

  const fileExistsCache = new Map();
  const resolveCache = new Map();

  function tryFile(p) {
    if (fileExistsCache.has(p)) return fileExistsCache.get(p);
    const exists = fs.existsSync(p) && fs.statSync(p).isFile();
    fileExistsCache.set(p, exists);
    return exists;
  }

  function applyAlias(specifier) {
    for (const key of sortedAliasKeys) {
      const isExact = key.endsWith('$');
      const aliasName = isExact ? key.slice(0, -1) : key;
      const target = aliasMap[key];

      if (isExact && specifier === aliasName) {
        return target;
      }
      if (!isExact && (specifier === aliasName || specifier.startsWith(`${aliasName}/`))) {
        return `${target}${specifier.slice(aliasName.length)}`;
      }
    }
    return specifier;
  }

  function resolveFile(absPath) {
    if (tryFile(absPath)) return absPath;

    for (const ext of EXTENSIONS) {
      if (tryFile(absPath + ext)) return absPath + ext;
    }

    if (absPath.endsWith('.vue') || absPath.endsWith('.mjs') || absPath.endsWith('.js')) {
      return null;
    }

    const indexCandidates = [
      path.join(absPath, 'index.mjs'),
      path.join(absPath, 'index.js'),
      path.join(absPath, 'index.vue'),
    ];
    for (const candidate of indexCandidates) {
      if (tryFile(candidate)) return candidate;
    }

    return null;
  }

  function resolveExportsEntry(exportsValue, pkgDir) {
    if (typeof exportsValue === 'string') {
      const p = path.resolve(pkgDir, exportsValue);
      return tryFile(p) ? p : null;
    }
    if (exportsValue && typeof exportsValue === 'object' && !Array.isArray(exportsValue)) {
      const supported = new Set(['module', 'import', 'default']);
      for (const key of Object.keys(exportsValue)) {
        if (supported.has(key)) {
          const result = resolveExportsEntry(exportsValue[key], pkgDir);
          if (result) return result;
        }
      }
    }
    return null;
  }

  function findPkgDir(pkgName, fromDir = rootPath) {
    let dir = fromDir;
    while (true) {
      const candidate = path.join(dir, 'node_modules', pkgName, 'package.json');
      if (fs.existsSync(candidate)) return path.dirname(candidate);
      const parent = path.dirname(dir);
      if (parent === dir) return null;
      dir = parent;
    }
  }

  function resolveNodeModuleAll(specifier, fromDir = rootPath) {
    const results = new Set();
    const parts = specifier.startsWith('@')
      ? specifier.split('/').slice(0, 2)
      : specifier.split('/').slice(0, 1);
    const pkgName = parts.join('/');
    const subpath = specifier.slice(pkgName.length) || '.';

    const pkgDir = findPkgDir(pkgName, fromDir);
    if (pkgDir) {
      const pkg = JSON.parse(fs.readFileSync(path.join(pkgDir, 'package.json'), 'utf-8'));

      if (pkg.exports) {
        let exportsEntry;
        if (typeof pkg.exports === 'string' || !pkg.exports['.']) {
          exportsEntry =
            subpath === '.'
              ? pkg.exports
              : pkg.exports[subpath] || pkg.exports[`${subpath}/index`];
        } else {
          exportsEntry = pkg.exports[subpath];
        }

        if (exportsEntry) {
          const resolved = resolveExportsEntry(exportsEntry, pkgDir);
          if (resolved) results.add(resolved);
        }
      }

      if (subpath === '.' || subpath === '/') {
        if (pkg.module) {
          const esmPath = path.resolve(pkgDir, pkg.module);
          if (tryFile(esmPath)) results.add(esmPath);
        }
        if (pkg.main) {
          const mainPath = path.resolve(pkgDir, pkg.main);
          if (tryFile(mainPath)) results.add(mainPath);
        }
      } else {
        const subDir = path.resolve(pkgDir, subpath.startsWith('.') ? subpath : subpath.slice(1));
        const subPkgJson = path.join(subDir, 'package.json');
        if (fs.existsSync(subPkgJson)) {
          const subPkg = JSON.parse(fs.readFileSync(subPkgJson, 'utf-8'));
          if (subPkg.module) {
            const esmPath = path.resolve(subDir, subPkg.module);
            if (tryFile(esmPath)) results.add(esmPath);
          }
        }
        const subFile = resolveFile(
          path.resolve(pkgDir, subpath.startsWith('.') ? subpath : subpath.slice(1)),
        );
        if (subFile) results.add(subFile);
      }

      if (typeof pkg.browser === 'string' && (subpath === '.' || subpath === '/')) {
        const browserPath = path.resolve(pkgDir, pkg.browser);
        if (tryFile(browserPath)) results.add(browserPath);
      }
      // Only file-level remaps are supported; specifier-level mappings
      // (e.g. { "react": "preact/compat" }) are not applied.
      if (pkg.browser && typeof pkg.browser === 'object') {
        const remapped = new Set();
        const excluded = new Set();
        for (const resolved of results) {
          const relPath = `./${path.relative(pkgDir, resolved).replace(/\\/g, '/')}`;
          if (Object.hasOwn(pkg.browser, relPath)) {
            if (pkg.browser[relPath] === false) {
              excluded.add(resolved);
            } else {
              const browserPath = path.resolve(pkgDir, pkg.browser[relPath]);
              if (tryFile(browserPath)) remapped.add(browserPath);
            }
          }
        }
        for (const p of excluded) results.delete(p);
        for (const p of remapped) results.add(p);
      }
    }

    if (results.size > 0) return [...results];

    if (fallbackResolve) {
      try {
        const resolved = fallbackResolve(specifier, fromDir);
        if (resolved) return [resolved];
      } catch {
        // fallback failed
      }
    }

    return null;
  }

  function resolveModuleAll(specifier, fromFile) {
    if (isBuiltin(specifier)) return null;

    const cacheKey = `${fromFile}\0${specifier}`;
    if (resolveCache.has(cacheKey)) return resolveCache.get(cacheKey);

    const aliased = applyAlias(specifier.replace(/\?vue3$/, ''));

    let results;
    if (path.isAbsolute(aliased)) {
      const r = resolveFile(aliased);
      results = r ? [r] : null;
    } else if (aliased.startsWith('.')) {
      const dir = path.dirname(fromFile);
      const r = resolveFile(path.resolve(dir, aliased));
      results = r ? [r] : null;
    } else {
      results = resolveNodeModuleAll(aliased, path.dirname(fromFile));
    }

    resolveCache.set(cacheKey, results);
    return results;
  }

  function resolveModule(specifier, fromFile) {
    const all = resolveModuleAll(specifier, fromFile);
    return all ? all[0] : null;
  }

  return { resolveModule, resolveModuleAll, tryFile };
}

/**
 * Extract the content of the first `<script>` block from a Vue SFC source string.
 *
 * @param {string} source - Full Vue SFC file content.
 * @returns {string} The script body, or empty string if no script block is found.
 */
export function extractScriptContent(source) {
  const scriptMatch = source.match(/<script(?:\s[^>]*)?>([^]*?)<\/script>/i);
  if (!scriptMatch) return '';
  return scriptMatch[1];
}

/**
 * Detect whether code is a Vue "app root" — a file that default-imports Vue
 * and instantiates it with `new Vue(...)`.
 *
 * `Vue.use()` calls are permitted (plugin registration is common in app roots).
 *
 * Disqualified when:
 *  - Named imports from `'vue'` exist (e.g. `import { computed } from 'vue'`)
 *  - The default import is used with property access other than `.use()`
 *    (e.g. `Vue.component()`, `Vue.extend()`)
 *
 * @param {string} code - JavaScript source code (not a full SFC — pass the
 *   extracted `<script>` content for Vue files).
 * @returns {boolean}
 */
export function detectAppRoot(code) {
  const stripped = code.replace(/\/\/[^\n]*/g, '').replace(/\/\*[\s\S]*?\*\//g, '');

  if (/import\s+\{[^}]*\}\s+from\s+['"]vue['"]/.test(stripped)) return false;

  const defaultImport = stripped.match(/import\s+([A-Za-z_$][\w$]*)\s+from\s+['"]vue['"]/);
  if (!defaultImport) return false;

  const name = defaultImport[1];
  const esc = name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

  if (!new RegExp(`new\\s+${esc}\\s*\\(`).test(stripped)) return false;

  const withoutUse = stripped.replace(new RegExp(`${esc}\\s*\\.\\s*use\\s*\\(`, 'g'), '');
  if (new RegExp(`${esc}\\s*\\.\\s*[A-Za-z_$]`).test(withoutUse)) return false;

  return true;
}

async function parseFile(filePath) {
  let source;
  try {
    source = await readFile(filePath, 'utf-8');
  } catch {
    return { imports: [], appRoot: false };
  }

  const isVue = filePath.endsWith('.vue');
  const code = isVue ? extractScriptContent(source) : source;
  if (!code) return { imports: [], appRoot: false };

  let imports = [];
  try {
    const [parsed] = parse(code);
    imports = parsed
      .filter((imp) => imp.n)
      .map((imp) => ({
        source: imp.n,
        dynamic: imp.d >= 0,
      }));
  } catch {
    // parse failed
  }

  const appRoot = detectAppRoot(code);

  return { imports, appRoot };
}

function isJsOrVue(resolved) {
  if (!resolved) return false;
  return resolved.endsWith('.js') || resolved.endsWith('.mjs') || resolved.endsWith('.vue');
}

async function buildGraph(entrypoints, resolver, { onProgress } = {}) {
  await init;

  const graph = {};
  const appRootSet = new Set();
  const visited = new Set();
  const queue = [];

  for (const absPath of Object.values(entrypoints)) {
    if (!visited.has(absPath) && resolver.tryFile(absPath)) {
      visited.add(absPath);
      queue.push(absPath);
    }
  }

  let idx = 0;
  let nextProgressAt = 500;
  const total = () => queue.length;

  while (idx < queue.length) {
    const batch = queue.slice(idx, idx + CONCURRENCY);
    idx += batch.length;

    // eslint-disable-next-line no-await-in-loop
    const results = await Promise.all(
      batch.map(async (filePath) => {
        const { imports, appRoot } = await parseFile(filePath);
        const resolved = imports.map((imp) => {
          const all = resolver.resolveModuleAll(imp.source, filePath);
          const r = all ? all[0] : null;
          return { source: imp.source, resolved: r, dynamic: imp.dynamic, alternatives: all };
        });
        return { filePath, resolved, appRoot };
      }),
    );

    for (const { filePath, resolved, appRoot } of results) {
      graph[filePath] = resolved.filter((imp) => !imp.resolved || isJsOrVue(imp.resolved));
      if (appRoot) appRootSet.add(filePath);
      for (const imp of resolved) {
        const paths = imp.alternatives || (imp.resolved ? [imp.resolved] : []);
        for (const p of paths) {
          if (isJsOrVue(p) && !visited.has(p)) {
            visited.add(p);
            queue.push(p);
          }
        }
      }
    }

    if (onProgress && idx >= nextProgressAt) {
      onProgress(idx, total());
      nextProgressAt = idx + 500;
    }
  }

  if (onProgress) onProgress(total(), total());

  return { graph, appRootSet };
}

function getInfectionSourceReason(imports, infectionSpecifiers) {
  for (const imp of imports) {
    if (infectionSpecifiers.some((s) => imp.source === s || imp.source.startsWith(`${s}/`))) {
      return imp.source;
    }
  }
  return null;
}

/**
 * Compute which files in an import graph are infected by propagating from
 * infection sources (files that import an infection specifier) through their
 * importers. App roots act as barriers — they become infected themselves but
 * do not propagate infection further.
 *
 * @param {Object<string, Array<{source: string, resolved: string|null}>>} graph
 *   Import graph: file path → array of import edges.
 * @param {Set<string>} appRootSet - File paths that are app roots (infection barriers).
 * @param {string[]} infectionSpecifiers - Specifiers whose import marks a file as an infection source.
 * @returns {{ infectedSet: Set<string>, infectionTriggers: Map<string, string[]> }}
 */
export function computeInfected(graph, appRootSet, infectionSpecifiers) {
  const infectedSet = new Set();
  const infectionTriggers = new Map();

  for (const [file, imports] of Object.entries(graph)) {
    const reason = getInfectionSourceReason(imports, infectionSpecifiers);
    if (reason) {
      infectedSet.add(file);
      infectionTriggers.set(file, [file]);
    }
  }

  let changed = true;
  while (changed) {
    changed = false;
    for (const [file, imports] of Object.entries(graph)) {
      if (!infectedSet.has(file)) {
        const sources = [];
        for (const imp of imports) {
          if (imp.resolved && infectedSet.has(imp.resolved) && !appRootSet.has(imp.resolved)) {
            sources.push(imp.resolved);
          }
        }
        if (sources.length) {
          infectedSet.add(file);
          infectionTriggers.set(file, sources);
          changed = true;
        }
      }
    }
  }

  return { infectedSet, infectionTriggers };
}

function findNearestInfectionReasons({ file, infectionTriggers, graph, infectionSpecifiers, maxShown = 3 }) {
  const reasons = [];
  let totalCount = 0;
  const visited = new Set();
  const queue = [file];
  visited.add(file);

  while (queue.length) {
    const current = queue.shift();
    const sources = infectionTriggers.get(current);
    if (sources) {
      for (const src of sources) {
        if (src === current) {
          const reason = getInfectionSourceReason(graph[current] || [], infectionSpecifiers);
          if (reason) {
            totalCount += 1;
            if (reasons.length < maxShown) {
              reasons.push({ file: current, reason });
            }
          }
        } else if (!visited.has(src)) {
          visited.add(src);
          queue.push(src);
        }
      }
    }
  }

  return { reasons, totalCount };
}

/**
 * Run the full infection analysis against a project.
 *
 * Builds an import graph starting from the given entrypoints, detects app roots,
 * propagates infection, and returns an annotated graph where each file is marked
 * with its infection and app-root status.
 *
 * @param {Object} options
 * @param {string} options.rootPath - Project root directory (used for node_modules lookup).
 * @param {Object<string, string>} options.entrypoints - Map of entrypoint name → absolute file path.
 * @param {string[]} options.infectionSpecifiers - Import specifiers that trigger infection
 *   (e.g. context alias keys). Both exact matches and prefix matches (`spec + '/'`) are checked.
 * @param {Object<string, string>} [options.aliasMap={}] - Webpack-style alias map for module resolution.
 * @param {Function} [options.fallbackResolve] - Optional fallback resolver (e.g. cjsRequire.resolve).
 * @param {Function} [options.onProgress] - Optional progress callback (parsed, total).
 * @returns {Promise<{entrypoints: Object, graph: Object}>} The annotated graph. Each graph entry
 *   contains `imports`, `infected`, `appRoot`, and (if infected) `infectionReasons` and `infectionReasonCount`.
 */
export async function analyze({ rootPath, entrypoints, infectionSpecifiers, aliasMap = {}, fallbackResolve, onProgress }) {
  const resolver = createResolver({ aliasMap, rootPath, fallbackResolve });
  const { graph, appRootSet } = await buildGraph(entrypoints, resolver, { onProgress });
  const { infectedSet, infectionTriggers } = computeInfected(
    graph,
    appRootSet,
    infectionSpecifiers,
  );

  const annotatedGraph = {};
  for (const [file, imports] of Object.entries(graph)) {
    const entry = {
      imports,
      infected: infectedSet.has(file),
      appRoot: appRootSet.has(file),
    };
    if (entry.infected) {
      const { reasons, totalCount } = findNearestInfectionReasons({
        file,
        infectionTriggers,
        graph,
        infectionSpecifiers,
        maxShown: 3,
      });
      entry.infectionReasons = reasons.map((s) => ({ file: s.file, reason: s.reason }));
      entry.infectionReasonCount = totalCount;
    }
    annotatedGraph[file] = entry;
  }

  return { entrypoints, graph: annotatedGraph };
}
