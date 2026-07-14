const path = require('path');
const glob = require('glob');
const { IS_EE, IS_JH, ROOT_PATH } = require('./webpack.constants');

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

  return {
    entries: autoEntries,
    entriesState: {
      autoEntriesCount: autoEntryKeys.length,
      watchAutoEntries,
    },
  };
}

module.exports = { generateEntries };
