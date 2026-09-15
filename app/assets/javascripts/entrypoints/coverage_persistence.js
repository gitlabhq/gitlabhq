/* eslint-disable no-underscore-dangle */

function getPersistedCoverage() {
  const storedPaths = localStorage.getItem('__coverage_paths__');
  if (storedPaths) {
    return JSON.parse(storedPaths);
  }
  return [];
}

function isHit(counter) {
  return Array.isArray(counter) ? counter.some((hits) => hits > 0) : counter > 0;
}

// Istanbul registers a file as soon as it is loaded, so counters tell us it ran.
function wasExecuted(fileCoverage) {
  return ['s', 'f', 'b'].some((counterType) =>
    Object.values(fileCoverage?.[counterType] || {}).some(isHit),
  );
}

function getExecutedPaths() {
  return Object.entries(window.__coverage__)
    .filter(([, fileCoverage]) => wasExecuted(fileCoverage))
    .map(([filePath]) => filePath);
}

function getCoverage() {
  if (!window.__coverage__) {
    // eslint-disable-next-line no-console
    console.warn('Coverage: __coverage__ object missing. Is Istanbul babel plugin enabled?');
    return getPersistedCoverage();
  }
  const filePaths = getExecutedPaths();
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
