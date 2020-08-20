import { NOT_IN_DB_PREFIX } from '../constants';
import {
  addPrefixToCustomVariableParams,
  addDashboardMetaDataToLink,
  normalizeCustomDashboardPath,
} from './utils';

const metricsIdsInPanel = panel =>
  panel.metrics.filter(metric => metric.metricId && metric.result).map(metric => metric.metricId);

/**
 * Returns a reference to the currently selected dashboard
 * from the list of dashboards.
 *
 * @param {Object} state
 */
export const selectedDashboard = (state, getters) => {
  const { allDashboards } = state;
  return (
    allDashboards.find(d => d.path === getters.fullDashboardPath) ||
    allDashboards.find(d => d.default) ||
    null
  );
};

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
  let groups = state.dashboard.panelGroups;
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
  let groups = state.dashboard.panelGroups;
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

/**
 * Metrics loaded from project-defined dashboards do not have a metric_id.
 * This getter checks which metrics are stored in the db (have a metric id)
 * This is hopefully a temporary solution until BE processes metrics before passing to FE
 *
 * Related:
 * https://gitlab.com/gitlab-org/gitlab/-/issues/28241
 * https://gitlab.com/gitlab-org/gitlab/-/merge_requests/27447
 */
export const metricsSavedToDb = state => {
  const metricIds = [];
  state.dashboard.panelGroups.forEach(({ panels }) => {
    panels.forEach(({ metrics }) => {
      const metricIdsInDb = metrics
        .filter(({ metricId }) => !metricId.startsWith(NOT_IN_DB_PREFIX))
        .map(({ metricId }) => metricId);

      metricIds.push(...metricIdsInDb);
    });
  });
  return metricIds;
};

/**
 * Filter environments by names.
 *
 * This is used in the environments dropdown with searchable input.
 *
 * @param {Object} state
 * @returns {Array} List of environments
 */
export const filteredEnvironments = state =>
  state.environments.filter(env =>
    env.name.toLowerCase().includes((state.environmentsSearchTerm || '').trim().toLowerCase()),
  );

/**
 * User-defined links from the yml file can have other
 * dashboard-related metadata baked into it. This method
 * returns modified links which will get rendered in the
 * metrics dashboard
 *
 * @param {Object} state
 * @returns {Array} modified array of links
 */
export const linksWithMetadata = state => {
  const metadata = {
    timeRange: state.timeRange,
  };
  return state.links?.map(addDashboardMetaDataToLink(metadata));
};

/**
 * Maps a variables array to an object for replacement in
 * prometheus queries.
 *
 * This method outputs an object in the below format
 *
 * {
 *   variables[key1]=value1,
 *   variables[key2]=value2,
 * }
 *
 * This is done so that the backend can identify the custom
 * user-defined variables coming through the URL and differentiate
 * from other variables used for Prometheus API endpoint.
 *
 * @param {Object} state - State containing variables provided by the user
 * @returns {Array} The custom variables object to be send to the API
 * in the format of {variables[key1]=value1, variables[key2]=value2}
 */

export const getCustomVariablesParams = state =>
  state.variables.reduce((acc, variable) => {
    const { name, value } = variable;
    if (value !== null) {
      acc[addPrefixToCustomVariableParams(name)] = value;
    }
    return acc;
  }, {});

/**
 * For a given custom dashboard file name, this method
 * returns the full file path.
 *
 * @param {Object} state
 * @returns {String} full dashboard path
 */
export const fullDashboardPath = state =>
  normalizeCustomDashboardPath(state.currentDashboard, state.customDashboardBasePath);
