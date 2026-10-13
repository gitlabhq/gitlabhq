// jsdom@20 only implements `performance.now`, but app code instruments page
// load with the User Timing API. Shimming the prototype also covers sinon
// modern fake timers, which rebuild their fake `performance` from it.
Object.assign(window.Performance.prototype, {
  mark: () => {},
  measure: () => {},
  clearMarks: () => {},
  clearMeasures: () => {},
  getEntriesByName: () => [],
  getEntriesByType: () => [],
});
