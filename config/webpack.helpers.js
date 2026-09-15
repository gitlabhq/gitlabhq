const path = require('path');
const glob = require('glob');
const { IS_EE, IS_JH, ROOT_PATH } = require('./webpack.constants');
const { pageEntryName } = require('./helpers/entry_points');
const {
  loadVue3Migrations,
  VUE3_MIGRATION_STATUS_ROLLOUT,
  VUE3_MIGRATION_STATUS_MIGRATED,
  appendVue3Query,
} = require('./helpers/vue3_migration_loader');

/**
 * Returns a new entry map with the `?vue3` variants: `rollout` adds an `<entry>.vue3`
 * sibling, `migrated` infects the entry in place. `defaultEntries` (`./main`) is shared
 * bootstrap and stays clean. Values are arrays for page entries, strings for global bundles.
 */
function applyVue3Migrations(entries, { defaultEntries = [], migrations } = {}) {
  const declared = migrations ?? loadVue3Migrations();
  const result = { ...entries };
  const infect = (modulePath) =>
    defaultEntries.includes(modulePath) ? modulePath : appendVue3Query(modulePath);

  for (const [entry, value] of Object.entries(entries)) {
    const migration = declared[entry];
    if (!migration) continue;

    const next = Array.isArray(value) ? value.map(infect) : infect(value);

    if (migration.status === VUE3_MIGRATION_STATUS_MIGRATED) {
      result[entry] = next;
    } else if (migration.status === VUE3_MIGRATION_STATUS_ROLLOUT) {
      result[`${entry}.vue3`] = next;
    }
  }

  return result;
}

function generateEntries(defaultEntries = [], { migrations } = {}) {
  // generate automatic entry points
  const autoEntries = {};
  const autoEntriesMap = {};
  const watchAutoEntries = [path.join(ROOT_PATH, 'app/assets/javascripts/pages/')];

  const pageEntries = glob.sync('pages/**/index.js', {
    cwd: path.join(ROOT_PATH, 'app/assets/javascripts'),
  });

  function generateAutoEntries(entryPath, prefix = '.') {
    autoEntriesMap[pageEntryName(entryPath)] = `${prefix}/${entryPath}`;
  }

  pageEntries.forEach((entryPath) => generateAutoEntries(entryPath));

  if (IS_EE) {
    const eePageEntries = glob.sync('pages/**/index.js', {
      cwd: path.join(ROOT_PATH, 'ee/app/assets/javascripts'),
    });
    eePageEntries.forEach((entryPath) => generateAutoEntries(entryPath, 'ee'));
    watchAutoEntries.push(path.join(ROOT_PATH, 'ee/app/assets/javascripts/pages/'));
  }

  if (IS_JH) {
    const jhPageEntries = glob.sync('pages/**/index.js', {
      cwd: path.join(ROOT_PATH, 'jh/app/assets/javascripts'),
    });
    jhPageEntries.forEach((entryPath) => generateAutoEntries(entryPath, 'jh'));
    watchAutoEntries.push(path.join(ROOT_PATH, 'jh/app/assets/javascripts/pages/'));
  }

  const autoEntryKeys = Object.keys(autoEntriesMap);

  // import ancestor entrypoints within their children
  autoEntryKeys.forEach((entry) => {
    const entryPaths = [autoEntriesMap[entry]];
    const segments = entry.split('.');
    while (segments.pop()) {
      const ancestor = segments.join('.');
      if (autoEntryKeys.includes(ancestor)) {
        entryPaths.unshift(autoEntriesMap[ancestor]);
      }
    }
    autoEntries[entry] = defaultEntries.concat(entryPaths);
  });

  return {
    entries: applyVue3Migrations(autoEntries, { defaultEntries, migrations }),
    entriesState: {
      autoEntriesCount: autoEntryKeys.length,
      watchAutoEntries,
    },
  };
}

module.exports = { generateEntries, applyVue3Migrations };
