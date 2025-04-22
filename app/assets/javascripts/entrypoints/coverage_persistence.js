/* eslint-disable no-underscore-dangle,@gitlab/require-i18n-strings,no-console */

function getPersistedCoverage() {
  const storedPaths = localStorage.getItem('__coverage_paths__');
  if (storedPaths) {
    return JSON.parse(storedPaths);
  }
  return [];
}

function getCoverage() {
  if (!window.__coverage__) {
    throw new Error(
      'Coverage object is missing on the page. Did you install Istanbul babel plugin and enable Webpack?',
    );
  }
  const filePaths = Object.keys(window.__coverage__);
  const existingPaths = getPersistedCoverage();
  return [...new Set([...existingPaths, ...filePaths])];
}

function persistCoverage(coverage = getCoverage()) {
  localStorage.setItem('__coverage_paths__', JSON.stringify(coverage));
  console.log(`Coverage paths saved: ${coverage.length} files tracked`);
}

function updateCoverage() {
  const coverage = getCoverage();
  persistCoverage(coverage);
  window.__coverageFilePaths = coverage;
}

window.addEventListener('beforeunload', () => {
  updateCoverage();
});

window.__coveragePathsPersistence = {
  update: updateCoverage,
  getPaths() {
    return window.__coverageFilePaths || [];
  },
  reset() {
    localStorage.removeItem('__coverage_paths__');
    window.__coverageFilePaths = [];
    console.log('Coverage paths reset.');
  },
};
