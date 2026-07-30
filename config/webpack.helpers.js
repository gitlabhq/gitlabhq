const path = require('path');
const glob = require('glob');
const { IS_EE, IS_JH, ROOT_PATH } = require('./webpack.constants');
const {
  loadVue3Migrations,
  VUE3_MIGRATION_STATUS_ROLLOUT,
  VUE3_MIGRATION_STATUS_MIGRATED,
  appendVue3Query,
} = require('./helpers/vue3_migration_loader');

function generateEntries(defaultEntries = []) {
  // generate automatic entry points
  const autoEntries = {};
  const autoEntriesMap = {};
  const watchAutoEntries = [path.join(ROOT_PATH, 'app/assets/javascripts/pages/')];

  const pageEntries = glob.sync('pages/**/index.js', {
    cwd: path.join(ROOT_PATH, 'app/assets/javascripts'),
  });

  function generateAutoEntries(entryPath, prefix = '.') {
    const chunkPath = entryPath.replace(/\/index\.js$/, '');
    const chunkName = chunkPath.replace(/\//g, '.');
    autoEntriesMap[chunkName] = `${prefix}/${entryPath}`;
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

  // Page entries with a `vue3_migration.yml` build Vue 3 bundles whose
  // paths are suffixed with `?vue3`. The infection plugins (Vite + Webpack)
  // pick up the marker on the entry request and propagate it through
  // imports. `defaultEntries` (e.g. `./main`) is shared bootstrap and
  // stays clean.
  //
  //   rollout   Emit a sibling `<entry>.vue3` next to the Vue 2 entry;
  //             Rails switches between them per request via the feature
  //             flag declared in the YAML.
  //   migrated  Infect the original entry in place: the Vue 2 bundle is
  //             never served for migrated pages, so it isn't built at all
  //             and the entry name needs no runtime rename.
  const migrations = loadVue3Migrations();
  Object.keys(autoEntries).forEach((entry) => {
    const migration = migrations[entry];
    if (!migration) return;

    const infectedPaths = autoEntries[entry].map((modulePath) =>
      defaultEntries.includes(modulePath) ? modulePath : appendVue3Query(modulePath),
    );

    if (migration.status === VUE3_MIGRATION_STATUS_MIGRATED) {
      autoEntries[entry] = infectedPaths;
    } else if (migration.status === VUE3_MIGRATION_STATUS_ROLLOUT) {
      autoEntries[`${entry}.vue3`] = infectedPaths;
    }
  });

  return {
    entries: autoEntries,
    entriesState: {
      autoEntriesCount: autoEntryKeys.length,
      watchAutoEntries,
    },
  };
}

module.exports = { generateEntries };
