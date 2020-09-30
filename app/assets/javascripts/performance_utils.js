export const performanceMarkAndMeasure = ({ mark, measures = [] } = {}) => {
  window.requestAnimationFrame(() => {
    if (mark && !performance.getEntriesByName(mark).length) {
      performance.mark(mark);
    }
    measures.forEach(measure => {
      window.requestAnimationFrame(() =>
        performance.measure(measure.name, measure.start, measure.end),
      );
    });
  });
};
