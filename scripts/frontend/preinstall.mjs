import { join } from 'node:path';
import { readFile, rm } from 'node:fs/promises';

const ROOT_PATH = join(import.meta.dirname, '..', '..');
const NODE_MODULES = join(ROOT_PATH, 'node_modules');
const INTEGRITY_FILE = join(NODE_MODULES, '.yarn-integrity');
const PACKAGE_JSON = join(ROOT_PATH, 'package.json');

function isAliasedDependency(x) {
  return x.includes('@npm:');
}
function serializeAliasedDependencyPatterns(obj) {
  return Object.entries(obj).map(([key, version]) => `${key}@${version}`);
}

async function readJSON(file) {
  return JSON.parse(await readFile(file, { encoding: 'utf-8' }));
}

async function getPrevTopLevelPatterns() {
  try {
    return (await readJSON(INTEGRITY_FILE))?.topLevelPatterns?.filter(isAliasedDependency);
  } catch {
    return [];
  }
}
async function getCurrentTopLevelPatterns() {
  try {
    const { dependencies, devDependencies } = await readJSON(PACKAGE_JSON);

    return serializeAliasedDependencyPatterns(dependencies)
      .concat(serializeAliasedDependencyPatterns(devDependencies))
      .filter(dep => isAliasedDependency(dep));
  } catch {
    return [];
  }
}

function arraysHaveSameItems(a1, a2) {
  return JSON.stringify(a1.sort()) === JSON.stringify(a2.sort());
}

const [prevTopLevelPatterns, currentTopLevelPatterns] = await Promise.all([
  getPrevTopLevelPatterns(),
  getCurrentTopLevelPatterns(),
]);

/**
 * Yarn seems to have problems at times, if one uses an <alias>@npm:<name>
 *  and those packages are being updated. In case one switches branches the
 *  node_modules folder seems to end up being a corrupted somehow
 */
if (!arraysHaveSameItems(prevTopLevelPatterns, currentTopLevelPatterns)) {
  console.error(
    '[WARNING] package.json changed significantly. Removing node_modules to be sure there are no problems.',
  );
  await rm(NODE_MODULES, { recursive: true, force: true });
}
