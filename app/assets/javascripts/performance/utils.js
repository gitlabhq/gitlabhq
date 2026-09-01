const timingBoundaryExists = (name) =>
  performance.getEntriesByName(name).length > 0 ||
  Boolean(performance.timing && name in performance.timing);

export const performanceMarkAndMeasure = ({ mark, measures = [], sync = false } = {}) => {
  const run = () => {
    if (mark && !performance.getEntriesByName(mark).length) {
      performance.mark(mark);
    }
    measures.forEach((measure) => {
      // Skip measures referencing marks that never got set (e.g. a start event
      // that never fired); performance.measure would throw a SyntaxError.
      const marksExist = [measure.start, measure.end].filter(Boolean).every(timingBoundaryExists);
      if (marksExist) {
        performance.measure(measure.name, measure.start, measure.end);
      }
    });
  };

  if (sync) {
    // requestAnimationFrame is paused in background tabs, so deferred marks can
    // be missing (or mistimed) when other code measures against them.
    run();
  } else {
    window.requestAnimationFrame(run);
  }
};
