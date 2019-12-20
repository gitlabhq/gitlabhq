const metricsIdsInPanel = panel =>
  panel.metrics.filter(metric => metric.metricId && metric.result).map(metric => metric.metricId);

/**
 * Get all state for metric in the dashboard or a group. The
 * states are not repeated so the dashboard or group can show
 * a global state.
 *
 * @param {Object} state
 * @returns {Function} A function that returns an array of
 * states in all the metric in the dashboard or group.
 */
export const getMetricStates = state => groupKey => {
  let groups = state.dashboard.panel_groups;
  if (groupKey) {
    groups = groups.filter(group => group.key === groupKey);
  }

  const metricStates = groups.reduce((acc, group) => {
    group.panels.forEach(panel => {
      panel.metrics.forEach(metric => {
        if (metric.state) {
          acc.push(metric.state);
        }
      });
    });
    return acc;
  }, []);

  // Deduplicate and sort array
  return Array.from(new Set(metricStates)).sort();
};

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
