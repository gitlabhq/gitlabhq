import { readFile } from 'node:fs/promises';
import contextAliasesShared from './context_aliases_shared.js';
import vue3InfectionShared from './vue3_infection_shared.js';

const { CONTEXT_ALIASES } = contextAliasesShared;
const {
  stripQuery,
  getQuery,
  hasVue3Query,
  hasSpecialQuery,
  appendVue3Query,
  loadScannerData,
  runInfectionScanner,
  createIsInfectable,
  logInfectionStats,
} = vue3InfectionShared;

const VUE3_SUFFIX = '.vue3-infected';
const VUE3_SUFFIX_RE = /\.vue3-infected(\.\w+)/;

const isInfectedBySuffix = (id) => VUE3_SUFFIX_RE.test(id);
const isInfected = (id) => hasVue3Query(id) || isInfectedBySuffix(id);
const isVirtualModule = (id) => id.startsWith('\0');

const cleanInfectedId = (id) => id.replace(VUE3_SUFFIX, '');

const appendVue3Suffix = (resolvedId) => {
  if (isInfected(resolvedId)) return resolvedId;
  const filePath = stripQuery(resolvedId);
  const query = getQuery(resolvedId);
  const ext = filePath.match(/(\.\w+)$/)?.[1] || '';
  const base = filePath.slice(0, -ext.length);
  const infectedPath = base + VUE3_SUFFIX + ext;
  return query ? `${infectedPath}${query}` : infectedPath;
};

export function Vue3InfectionPlugin() {
  const contextAliasKeys = Object.keys(CONTEXT_ALIASES);
  let isBuild = false;
  let isInfectable = null;

  return {
    name: 'gitlab-vue3-infection',
    enforce: 'pre',

    configResolved(config) {
      isBuild = config.command === 'build';

      runInfectionScanner();
      const scannerGraph = loadScannerData();

      isInfectable = createIsInfectable(scannerGraph, {
        // Vite pre-bundled deps have their internal imports resolved at pre-bundle time,
        // so appending ?vue3 only creates duplicate module instances without changing behavior.
        // CONTEXT_ALIASES already handle Vue ecosystem packages that need redirection.
        shouldExclude: (filePath) => filePath.includes('/tmp/cache/vite/'),
      });
    },

    buildEnd() {
      const allIds = [...this.getModuleIds()];
      const infected = new Set();
      const clean = new Set();

      for (const id of allIds) {
        const cleanPath = isBuild ? cleanInfectedId(stripQuery(id)) : stripQuery(id);
        if (isInfected(id)) {
          infected.add(cleanPath);
        } else {
          clean.add(cleanPath);
        }
      }

      logInfectionStats({ total: allIds.length, infected, clean });
    },

    async load(id) {
      if (!isBuild) return null;
      if (isVirtualModule(id) || !isInfectedBySuffix(id) || hasSpecialQuery(id)) return null;
      const realPath = cleanInfectedId(stripQuery(id));
      return readFile(realPath, 'utf-8');
    },

    async resolveId(source, importer, options) {
      const explicitlyRequestsInfection = hasVue3Query(source);

      if (
        isVirtualModule(source) ||
        hasSpecialQuery(source) ||
        (!explicitlyRequestsInfection && !isInfected(importer))
      ) {
        return null;
      }

      const resolve = (id) => this.resolve(id, importer, { ...options, skipSelf: true });
      const sourceToResolve = explicitlyRequestsInfection ? stripQuery(source) : source;
      const appendVue3 = isBuild ? appendVue3Suffix : appendVue3Query;

      const aliasKey = contextAliasKeys.find((k) => sourceToResolve === k);
      if (aliasKey) {
        const importerPath = isBuild
          ? cleanInfectedId(stripQuery(importer))
          : stripQuery(importer);
        const resolved = await resolve(CONTEXT_ALIASES[aliasKey]);
        if (!resolved || stripQuery(resolved.id) === importerPath) return null;
        return appendVue3(resolved.id);
      }

      const resolved = await resolve(sourceToResolve);
      if (resolved && isInfectable(resolved.id)) {
        return appendVue3(resolved.id);
      }

      return null;
    },
  };
}
