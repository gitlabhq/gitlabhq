/* eslint-disable no-param-reassign */
const path = require('path');
const { CONTEXT_ALIASES } = require('../helpers/context_aliases_shared');
const {
  stripQuery,
  hasVue3Query,
  hasSpecialQuery,
  appendVue3Query,
  loadScannerData,
  runInfectionScanner,
  createIsInfectable,
  logInfectionStats,
} = require('../helpers/vue3_infection_shared');

// Packages injected by loaders (not statically imported) that the scanner cannot discover.
const SCANNER_BYPASS_PACKAGES = ['core-js', 'webpack', 'css-loader', 'vue-hot-reload-api'];

const PLUGIN_NAME = 'WebpackVue3InfectionPlugin';
const contextAliasKeys = Object.keys(CONTEXT_ALIASES);

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

    result.resource = appendVue3Query(resolvedResource);
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

      logInfectionStats({ total: modules.length, infected, clean });
    });
  });
};

class WebpackVue3InfectionPlugin {
  // eslint-disable-next-line class-methods-use-this
  apply(compiler) {
    runInfectionScanner();
    const scannerGraph = loadScannerData();

    const isInfectable = createIsInfectable(scannerGraph, {
      // Some node_modules are injected by loaders (e.g. core-js via Babel) rather
      // than statically imported in source code, so they never appear in the
      // scanner's import graph.  Bypass the scanner check for these packages.
      shouldBypass: (clean) =>
        SCANNER_BYPASS_PACKAGES.some((pkg) => clean.includes(`/node_modules/${pkg}/`)),
    });
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
