/* eslint-disable no-underscore-dangle */

function getPersistedCoverage() {
  const storedPaths = localStorage.getItem('__coverage_paths__');
  if (storedPaths) {
    return JSON.parse(storedPaths);
  }
  return [];
}

function getCoverage() {
  if (!window.__coverage__) {
    // eslint-disable-next-line no-console
    console.warn('Coverage: __coverage__ object missing. Is Istanbul babel plugin enabled?');
    return getPersistedCoverage();
  }
  const filePaths = Object.keys(window.__coverage__);
  const existingPaths = getPersistedCoverage();
  return [...new Set([...existingPaths, ...filePaths])];
}

function persistCoverage(coverage = getCoverage()) {
  localStorage.setItem('__coverage_paths__', JSON.stringify(coverage));
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
  },
};
