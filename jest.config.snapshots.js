const fs = require('fs');
const path = require('path');
const baseConfig = require('./jest.config.base');

function findSnapshotTestsFromDir(dir, results = []) {
  fs.readdirSync(dir).forEach((file) => {
    const fullPath = path.join(dir, file);
    if (fs.lstatSync(fullPath).isDirectory()) {
      findSnapshotTestsFromDir(fullPath, results);
    } else {
      const fileContent = fs.readFileSync(fullPath, 'utf8');
      if (/toMatchSnapshot|toMatchInlineSnapshot/.test(fileContent)) {
        results.push(`<rootDir>/${fullPath}`);
      }
    }
  });
  return results;
}

function saveArrayToFile(array, fileName) {
  fs.writeFile(fileName, JSON.stringify(array, null, 2), (err) => {
    if (err) {
      console.error(`Error writing Array data to ${fileName}:`, err);
    }
  });
}

module.exports = () => {
  const testMatch = [
    ...findSnapshotTestsFromDir('spec/frontend'),
    ...findSnapshotTestsFromDir('ee/spec/frontend'),
  ];

  const { CI, SNAPSHOT_TEST_MATCH_FILE } = process.env;
  if (CI && SNAPSHOT_TEST_MATCH_FILE) {
    saveArrayToFile(testMatch, SNAPSHOT_TEST_MATCH_FILE);
  }

  return {
    ...baseConfig('spec/frontend'),
    roots: ['<rootDir>/spec/frontend'],
    rootsEE: ['<rootDir>/ee/spec/frontend'],
    rootsJH: ['<rootDir>/jh/spec/frontend'],
    testMatch,
  };
};
