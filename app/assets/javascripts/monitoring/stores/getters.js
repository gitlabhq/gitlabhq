const metricsIdsInPanel = panel =>
  panel.metrics.filter(metric => metric.metricId && metric.result).map(metric => metric.metricId);

/**
 * Getter to obtain the list of metric ids that have data
 *
 * Useful to understand which parts of the dashboard should
 * be displayed. It is a Vuex Method-Style Access getter.
 *
 * @param {Object} state
 * @returns {Function} A function that returns an array of
 * metrics in the dashboard that contain results, optionally
 * filtered by group key.
 */
export const metricsWithData = state => groupKey => {
  let groups = state.dashboard.panel_groups;
  if (groupKey) {
    groups = groups.filter(group => group.key === groupKey);
  }

  const res = [];
  groups.forEach(group => {
    group.panels.forEach(panel => {
      res.push(...metricsIdsInPanel(panel));
    });
  });

  return res;
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
