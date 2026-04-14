/* eslint-disable no-param-reassign */
const path = require('path');
const { readFileSync, existsSync } = require('fs');
const { spawnSync } = require('child_process');
const {
  CONTEXT_ALIASES,
  INFECTABLE_RE,
  INFECTION_BLOCKLIST,
} = require('../helpers/context_aliases_shared');

const ROOT_PATH = path.resolve(__dirname, '..', '..');
const SCANNER_JSON_PATH = path.join(ROOT_PATH, 'tmp', 'infection_scanner.json');

// Packages injected by loaders (not statically imported) that the scanner cannot discover.
const SCANNER_BYPASS_PACKAGES = ['core-js', 'webpack', 'css-loader', 'vue-hot-reload-api'];

const PLUGIN_NAME = 'WebpackVue3InfectionPlugin';
const VUE3_QUERY = '?vue3';
const contextAliasKeys = Object.keys(CONTEXT_ALIASES);

const stripQuery = (id) => {
  if (!id) return '';
  const idx = id.indexOf('?');
  return idx >= 0 ? id.substr(0, idx) : id;
};

const getQuery = (id) => {
  if (!id) return '';
  const idx = id.indexOf('?');
  return idx >= 0 ? id.substr(idx) : '';
};

const hasVue3Query = (id) => {
  if (!id) return false;
  return getQuery(id).includes('vue3');
};

const SPECIAL_QUERIES = ['vue', 'worker', 'raw', 'url', 'inline', 'sharedworker'];
const hasSpecialQuery = (id) => {
  const query = getQuery(id);
  if (!query) return false;
  const params = new URLSearchParams(query.slice(1));
  return SPECIAL_QUERIES.some((q) => params.has(q));
};

function loadScannerData() {
  if (!existsSync(SCANNER_JSON_PATH)) {
    throw new Error(
      `[vue3-infection] Infection scanner data not found at ${SCANNER_JSON_PATH}.\n` +
        `Run: node scripts/frontend/infection_scanner/infection_scanner.mjs`,
    );
  }
  const data = JSON.parse(readFileSync(SCANNER_JSON_PATH, 'utf-8'));
  const graph = new Map();
  for (const [filePath, entry] of Object.entries(data.graph)) {
    graph.set(filePath, { infected: entry.infected, appRoot: entry.appRoot });
  }
  console.log(
    `[vue3-infection] Loaded scanner data: ${graph.size} files, ` +
      `${[...graph.values()].filter((e) => e.infected).length} infected`,
  );
  return graph;
}

const createIsInfectable = (scannerGraph) => (id) => {
  const clean = stripQuery(id);
  if (!INFECTABLE_RE.test(clean)) return false;
  if (INFECTION_BLOCKLIST.some((blocked) => clean.includes(blocked))) return false;
  if (!scannerGraph) return true;
  // Some node_modules are injected by loaders (e.g. core-js via Babel) rather
  // than statically imported in source code, so they never appear in the
  // scanner's import graph.  Bypass the scanner check for these packages.
  if (SCANNER_BYPASS_PACKAGES.some((pkg) => clean.includes(`/node_modules/${pkg}/`))) return true;
  const entry = scannerGraph.get(clean);
  if (!entry) {
    throw new Error(
      `[vue3-infection] File not found in scanner data: ${clean}\n` +
        `Re-run: node scripts/frontend/infection_scanner/infection_scanner.mjs`,
    );
  }
  return entry.infected;
};

const appendVue3 = (resource) => {
  if (hasVue3Query(resource)) return resource;
  const query = getQuery(resource);
  const filePath = stripQuery(resource);
  return query ? `${filePath}${query}&vue3` : `${filePath}${VUE3_QUERY}`;
};

const rebuildRequest = (loaders, resource) => {
  return loaders
    .map((l) => {
      if (typeof l === 'string') return l;
      let ident = l.loader;
      if (l.options) {
        if (typeof l.options === 'string') {
          ident += `?${l.options}`;
        } else if (l.ident) {
          ident += `??${l.ident}`;
        } else {
          ident += `?${JSON.stringify(l.options)}`;
        }
      }
      return ident;
    })
    .concat([resource])
    .join('!');
};

const resolveAliasTargets = () => {
  const resolved = {};
  for (const key of contextAliasKeys) {
    const target = CONTEXT_ALIASES[key];
    if (path.isAbsolute(target)) {
      resolved[key] = target;
    } else {
      try {
        resolved[key] = require.resolve(target);
      } catch (e) {
        resolved[key] = target;
      }
    }
  }
  return resolved;
};

// eslint-disable-next-line max-params
const applyInfectionResolving = (nmf, infectedDeps, resolvedTargets, isInfectable) => {
  const pendingInfections = new WeakSet();

  nmf.hooks.beforeResolve.tap(PLUGIN_NAME, (result) => {
    if (!result) return undefined;

    const { request, contextInfo, dependencies } = result;
    const issuer = (contextInfo && contextInfo.issuer) || '';
    const requestExplicitlyInfected = hasVue3Query(request);
    // In webpack 4, contextInfo.issuer is derived from NormalModule.nameForCondition()
    // which strips query strings.  This means we cannot distinguish file.js (clean)
    // from file.js?vue3 (infected) by looking at the issuer path alone.
    // Instead we check whether the *dependency object* was tagged by the
    // succeedModule hook that fires after an infected module is built.
    const dep = dependencies && dependencies[0];
    const importerIsInfected = dep && infectedDeps.has(dep);

    if (!requestExplicitlyInfected && !importerIsInfected) return undefined;
    if (hasSpecialQuery(request)) return undefined;
    if (request.includes('!')) return undefined;

    const cleanRequest = requestExplicitlyInfected ? stripQuery(request) : request;

    const aliasKey = contextAliasKeys.find((k) => cleanRequest === k);
    if (aliasKey) {
      const aliasTarget = resolvedTargets[aliasKey];
      if (aliasTarget === issuer) return undefined;
      result.request = aliasTarget;
      if (dep) {
        pendingInfections.add(dep);
      }
      return undefined;
    }

    if (requestExplicitlyInfected) {
      result.request = cleanRequest;
    }

    if (dep) {
      pendingInfections.add(dep);
    }

    return undefined;
  });

  nmf.hooks.afterResolve.tap(PLUGIN_NAME, (result) => {
    if (!result) return undefined;

    const shouldInfect =
      result.dependencies &&
      result.dependencies[0] &&
      pendingInfections.has(result.dependencies[0]);

    if (!shouldInfect) return undefined;

    const resolvedResource = result.resource;

    if (hasSpecialQuery(resolvedResource) || !isInfectable(resolvedResource)) return undefined;

    result.resource = appendVue3(resolvedResource);
    result.request = rebuildRequest(result.loaders, result.resource);
    result.userRequest = result.resource;

    return undefined;
  });
};

const applyStatsReporting = (compiler) => {
  compiler.hooks.compilation.tap(PLUGIN_NAME, (compilation) => {
    compilation.hooks.finishModules.tap(PLUGIN_NAME, (modules) => {
      const infected = new Set();
      const clean = new Set();

      modules.forEach((mod) => {
        if (!mod.resource) return;
        const cleanPath = stripQuery(mod.resource);
        if (hasVue3Query(mod.resource)) {
          infected.add(cleanPath);
        } else {
          clean.add(cleanPath);
        }
      });

      const duplicated = [...infected].filter((p) => clean.has(p));
      console.log(
        `[vue3-infection] total: ${modules.length}, ` +
          `infected: ${infected.size}, duplicated: ${duplicated.length}`,
      );
    });
  });
};

class WebpackVue3InfectionPlugin {
  // eslint-disable-next-line class-methods-use-this
  apply(compiler) {
    let scannerGraph = null;

    if (process.env.SKIP_INFECTION_SCANNER) {
      console.log(
        '[vue3-infection] SKIP_INFECTION_SCANNER set — scanner disabled, all files infectable.',
      );
    } else {
      if (compiler.options.mode !== 'production') {
        const scriptPath = path.join(
          ROOT_PATH,
          'scripts/frontend/infection_scanner/infection_scanner.mjs',
        );
        console.log('[vue3-infection] Running infection scanner...');
        const res = spawnSync(process.execPath, [scriptPath], {
          cwd: ROOT_PATH,
          stdio: 'inherit',
          env: process.env,
        });
        if (res.status !== 0) {
          console.warn(
            `[vue3-infection] Infection scanner failed (code ${res.status}). Continuing with stale data if available.`,
          );
        }
      }

      scannerGraph = loadScannerData();
    }

    const isInfectable = createIsInfectable(scannerGraph);
    const infectedDeps = new WeakSet();
    const resolvedTargets = resolveAliasTargets();
    // Tag every dependency of an infected module so that beforeResolve can
    // propagate infection without relying on file-path matching.
    // succeedModule fires after a module is built (and its dependencies are
    // extracted) but before those dependencies are resolved — exactly the
    // right timing.
    compiler.hooks.compilation.tap(PLUGIN_NAME, (compilation) => {
      compilation.hooks.succeedModule.tap(PLUGIN_NAME, (module) => {
        // A module should propagate infection if it directly has ?vue3,
        // or if it's a vue-loader sub-request (?vue&type=script etc.)
        // of an infected .vue file.  We check the issuer's resource
        // (which preserves the full query) instead of a shared path set,
        // because the same .vue file can be loaded both infected and
        // non-infected from different entry points.
        const isInfectedVueSubRequest =
          hasSpecialQuery(module.resource) && module.issuer && hasVue3Query(module.issuer.resource);

        if (!hasVue3Query(module.resource) && !isInfectedVueSubRequest) return;

        const tagBlock = (block) => {
          for (const dep of block.dependencies) {
            infectedDeps.add(dep);
          }
          for (const child of block.blocks || []) {
            tagBlock(child);
          }
        };
        tagBlock(module);
      });
    });

    compiler.hooks.normalModuleFactory.tap(PLUGIN_NAME, (nmf) => {
      applyInfectionResolving(nmf, infectedDeps, resolvedTargets, isInfectable);
    });

    applyStatsReporting(compiler);
  }
}

module.exports = WebpackVue3InfectionPlugin;
