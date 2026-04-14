import { createRequire } from 'node:module';
import { readFile } from 'node:fs/promises';
import { readFileSync, existsSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import path from 'node:path';

const require = createRequire(import.meta.url);
const { CONTEXT_ALIASES, INFECTABLE_RE, INFECTION_BLOCKLIST } = require('./context_aliases_shared');

const ROOT_PATH = path.resolve(import.meta.dirname, '..', '..');
const SCANNER_JSON_PATH = path.join(ROOT_PATH, 'tmp', 'infection_scanner.json');

const VUE3_QUERY = 'vue3';
const VUE3_SUFFIX = '.vue3-infected';
const VUE3_SUFFIX_RE = /\.vue3-infected(\.\w+)/;

const toURL = (id) => new URL(id, 'https://dummy.base');

const parseId = (id) => {
  if (!id) return { path: '', params: new URLSearchParams() };
  const url = toURL(id);
  return { path: url.pathname, params: url.searchParams };
};

const isInfectedByQuery = (id) => parseId(id).params.has(VUE3_QUERY);
const isInfectedBySuffix = (id) => VUE3_SUFFIX_RE.test(id);
const isInfected = (id) => isInfectedByQuery(id) || isInfectedBySuffix(id);
const SPECIAL_QUERIES = ['vue', 'worker', 'raw', 'url', 'inline', 'sharedworker'];
const hasSpecialQuery = (id) => {
  const { params } = parseId(id);
  return SPECIAL_QUERIES.some((q) => params.has(q));
};
const isVirtualModule = (id) => id.startsWith('\0');

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

const cleanInfectedId = (id) => id.replace(VUE3_SUFFIX, '');

const appendVue3Query = (resolvedId) => {
  if (isInfected(resolvedId)) return resolvedId;
  const url = toURL(resolvedId);
  url.searchParams.set(VUE3_QUERY, '');
  return url.pathname + url.search;
};

const appendVue3Suffix = (resolvedId) => {
  if (isInfected(resolvedId)) return resolvedId;
  const { path: filePath, params } = parseId(resolvedId);
  const ext = filePath.match(/(\.\w+)$/)?.[1] || '';
  const base = filePath.slice(0, -ext.length);
  const infectedPath = base + VUE3_SUFFIX + ext;
  return params.size > 0 ? `${infectedPath}?${params.toString()}` : infectedPath;
};

export function Vue3InfectionPlugin() {
  const contextAliasKeys = Object.keys(CONTEXT_ALIASES);
  let isBuild = false;
  let scannerGraph = null;

  const isInfectable = (id) => {
    const { path: filePath } = parseId(id);
    if (!INFECTABLE_RE.test(filePath)) return false;
    if (INFECTION_BLOCKLIST.some((blocked) => filePath.includes(blocked))) return false;
    if (!scannerGraph) return true;
    // Vite pre-bundled deps have their internal imports resolved at pre-bundle time,
    // so appending ?vue3 only creates duplicate module instances without changing behavior.
    // CONTEXT_ALIASES already handle Vue ecosystem packages that need redirection.
    if (filePath.includes('/tmp/cache/vite/')) return false;
    const entry = scannerGraph.get(filePath);
    if (!entry) {
      throw new Error(
        `[vue3-infection] File not found in scanner data: ${filePath}\n` +
          `Re-run: node scripts/frontend/infection_scanner/infection_scanner.mjs`,
      );
    }
    return entry.infected;
  };

  return {
    name: 'gitlab-vue3-infection',
    enforce: 'pre',

    configResolved(config) {
      isBuild = config.command === 'build';

      if (process.env.SKIP_INFECTION_SCANNER) {
        console.log(
          '[vue3-infection] SKIP_INFECTION_SCANNER set — scanner disabled, all files infectable.',
        );
        scannerGraph = null;
        return;
      }

      if (!isBuild) {
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
    },

    buildEnd() {
      const allIds = [...this.getModuleIds()];
      const infected = new Set();
      const clean = new Set();

      for (const id of allIds) {
        const cleanPath = isBuild ? cleanInfectedId(parseId(id).path) : parseId(id).path;
        if (isInfected(id)) {
          infected.add(cleanPath);
        } else {
          clean.add(cleanPath);
        }
      }

      const duplicated = [...infected].filter((p) => clean.has(p));
      console.log(
        `[vue3-infection] total: ${allIds.length}, ` +
          `infected: ${infected.size}, duplicated: ${duplicated.length}`,
      );
    },

    async load(id) {
      if (!isBuild) return null;
      if (isVirtualModule(id) || !isInfectedBySuffix(id) || hasSpecialQuery(id)) return null;
      const { path: filePath } = parseId(id);
      const realPath = cleanInfectedId(filePath);
      return readFile(realPath, 'utf-8');
    },

    async resolveId(source, importer, options) {
      const { params: sourceParams } = parseId(source);
      const explicitlyRequestsInfection = sourceParams.has(VUE3_QUERY);

      if (
        isVirtualModule(source) ||
        hasSpecialQuery(source) ||
        (!explicitlyRequestsInfection && !isInfected(importer))
      ) {
        return null;
      }

      const resolve = (id) => this.resolve(id, importer, { ...options, skipSelf: true });
      const sourceToResolve = explicitlyRequestsInfection ? source.replace(/\?.*$/, '') : source;
      const appendVue3 = isBuild ? appendVue3Suffix : appendVue3Query;

      const aliasKey = contextAliasKeys.find((k) => sourceToResolve === k);
      if (aliasKey) {
        const importerPath = isBuild
          ? cleanInfectedId(parseId(importer).path)
          : parseId(importer).path;
        const resolved = await resolve(CONTEXT_ALIASES[aliasKey]);
        if (!resolved || parseId(resolved.id).path === importerPath) return null;
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
