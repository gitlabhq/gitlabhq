const path = require('path');
const { readFileSync, existsSync } = require('fs');
const { spawnSync } = require('child_process');
const { INFECTABLE_RE, INFECTION_BLOCKLIST } = require('./context_aliases_shared');

const ROOT_PATH = path.resolve(__dirname, '..', '..');
const SCANNER_JSON_PATH = path.join(ROOT_PATH, 'tmp', 'infection_scanner.json');

const VUE3_QUERY = 'vue3';
const SPECIAL_QUERIES = ['vue', 'worker', 'raw', 'url', 'inline', 'sharedworker'];

/**
 * Strip the query string from a module ID.
 * @param {string} id
 * @returns {string}
 */
const stripQuery = (id) => {
  if (!id) return '';
  const idx = id.indexOf('?');
  return idx >= 0 ? id.substring(0, idx) : id;
};

/**
 * Get the query string (including the leading '?') from a module ID.
 * @param {string} id
 * @returns {string}
 */
const getQuery = (id) => {
  if (!id) return '';
  const idx = id.indexOf('?');
  return idx >= 0 ? id.substring(idx) : '';
};

/**
 * Check whether a module ID has the `?vue3` infection marker.
 * @param {string} id
 * @returns {boolean}
 */
const hasVue3Query = (id) => {
  if (!id) return false;
  return getQuery(id).includes(VUE3_QUERY);
};

/**
 * Check whether a module ID has a special query that should not be infected.
 * @param {string} id
 * @returns {boolean}
 */
const hasSpecialQuery = (id) => {
  const query = getQuery(id);
  if (!query) return false;
  const params = new URLSearchParams(query.slice(1));
  return SPECIAL_QUERIES.some((q) => params.has(q));
};

/**
 * Append `?vue3` (or `&vue3`) to a resolved module ID.
 * No-op if the ID is already infected.
 * @param {string} resource
 * @returns {string}
 */
const appendVue3Query = (resource) => {
  if (hasVue3Query(resource)) return resource;
  const query = getQuery(resource);
  const filePath = stripQuery(resource);
  return query ? `${filePath}${query}&vue3` : `${filePath}?${VUE3_QUERY}`;
};

/**
 * Load and parse the infection scanner JSON data.
 * @returns {Map<string, {infected: boolean, appRoot: string}>}
 */
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

/**
 * Run the infection scanner script synchronously.
 * Logs a warning on failure but does not throw.
 */
function runInfectionScanner() {
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

/**
 * Create an `isInfectable` predicate for a given scanner graph.
 *
 * @param {Map|null} scannerGraph - The loaded scanner graph (or null to skip graph checks).
 * @param {Object} [options]
 * @param {function(string): boolean} [options.shouldExclude] - Optional callback that returns
 *   true for clean paths that should always be considered NOT infectable, regardless of the
 *   scanner graph (e.g. Vite pre-bundled deps in `/tmp/cache/vite/`).
 * @param {function(string): boolean} [options.shouldBypass] - Optional callback that returns
 *   true for clean paths that should bypass the scanner graph lookup and be considered
 *   infectable (e.g. loader-injected packages in Webpack like core-js).
 * @returns {function(string): boolean}
 */
const createIsInfectable = (scannerGraph, { shouldExclude, shouldBypass } = {}) => {
  return (id) => {
    const clean = stripQuery(id);
    if (!INFECTABLE_RE.test(clean)) return false;
    if (INFECTION_BLOCKLIST.some((blocked) => clean.includes(blocked))) return false;
    if (!scannerGraph) return true;
    if (shouldExclude && shouldExclude(clean)) return false;
    if (shouldBypass && shouldBypass(clean)) return true;
    const entry = scannerGraph.get(clean);
    if (!entry) {
      throw new Error(
        `[vue3-infection] File not found in scanner data: ${clean}\n` +
          `Re-run: node scripts/frontend/infection_scanner/infection_scanner.mjs`,
      );
    }
    return entry.infected;
  };
};

/**
 * Log infection stats (total modules, infected count, duplicated count).
 *
 * @param {Object} options
 * @param {number} options.total - Total number of modules.
 * @param {Set<string>} options.infected - Set of infected clean paths.
 * @param {Set<string>} options.clean - Set of non-infected clean paths.
 */
function logInfectionStats({ total, infected, clean }) {
  const duplicated = [...infected].filter((p) => clean.has(p));
  console.log(
    `[vue3-infection] total: ${total}, ` +
      `infected: ${infected.size}, duplicated: ${duplicated.length}`,
  );
}

module.exports = {
  stripQuery,
  getQuery,
  hasVue3Query,
  hasSpecialQuery,
  appendVue3Query,
  loadScannerData,
  runInfectionScanner,
  createIsInfectable,
  logInfectionStats,
};
