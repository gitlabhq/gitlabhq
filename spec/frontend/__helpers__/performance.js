// FIXME(vslobodin): Remove this stub once we have migrated to Jest 28.
// NOTE: Do not try to optimize these stubs as Jest 27 overwrites
// the "global.performance" object in every suite where fake timers are enabled.
export const stubPerformanceWebAPI = () => {
  global.performance.getEntriesByName = () => [];
  global.performance.mark = () => {};
  global.performance.measure = () => {};
};
