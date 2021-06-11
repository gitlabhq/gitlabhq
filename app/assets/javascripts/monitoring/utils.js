import { pickBy, mapKeys } from 'lodash';
import { parseBoolean } from '~/lib/utils/common_utils';
import {
  timeRangeParamNames,
  timeRangeFromParams,
  timeRangeToParams,
} from '~/lib/utils/datetime_range';
import {
  queryToObject,
  mergeUrlParams,
  removeParams,
  updateHistory,
} from '~/lib/utils/url_utility';
import { VARIABLE_PREFIX } from './constants';

/**
 * Extracts the initial state and props from HTML dataset
 * and places them in separate objects to setup bundle.
 * @param {*} dataset
 */
export const stateAndPropsFromDataset = (dataset = {}) => {
  const {
    currentDashboard,
    deploymentsEndpoint,
    dashboardEndpoint,
    dashboardsEndpoint,
    panelPreviewEndpoint,
    dashboardTimezone,
    canAccessOperationsSettings,
    operationsSettingsPath,
    projectPath,
    logsPath,
    externalDashboardUrl,
    currentEnvironmentName,
    customDashboardBasePath,
    addDashboardDocumentationPath,
    ...dataProps
  } = dataset;

  // HTML attributes are always strings, parse other types.
  dataProps.hasMetrics = parseBoolean(dataProps.hasMetrics);
  dataProps.customMetricsAvailable = parseBoolean(dataProps.customMetricsAvailable);
  dataProps.prometheusAlertsAvailable = parseBoolean(dataProps.prometheusAlertsAvailable);
  dataProps.hasManagedPrometheus = parseBoolean(dataProps.hasManagedPrometheus);

  return {
    initState: {
      currentDashboard,
      deploymentsEndpoint,
      dashboardEndpoint,
      dashboardsEndpoint,
      panelPreviewEndpoint,
      dashboardTimezone,
      canAccessOperationsSettings,
      operationsSettingsPath,
      projectPath,
      logsPath,
      externalDashboardUrl,
      currentEnvironmentName,
      customDashboardBasePath,
      addDashboardDocumentationPath,
    },
    dataProps,
  };
};

/**
 * List of non time range url parameters
 * This will be removed once we add support for free text variables
 * via the dashboard yaml files in https://gitlab.com/gitlab-org/gitlab/-/issues/215689
 */
export const dashboardParams = ['dashboard', 'group', 'title', 'y_label', 'embedded'];

/**
 * This method is used to validate if the graph data format for a chart component
 * that needs a time series as a response from a prometheus query (queryRange) is
 * of a valid format or not.
 * @param {Object} graphData  the graph data response from a prometheus request
 * @returns {boolean} whether the graphData format is correct
 */
export const graphDataValidatorForValues = (isValues, graphData) => {
  const responseValueKeyName = isValues ? 'value' : 'values';
  return (
    Array.isArray(graphData.metrics) &&
    graphData.metrics.filter((query) => {
      if (Array.isArray(query.result)) {
        return (
          query.result.filter((res) => Array.isArray(res[responseValueKeyName])).length ===
          query.result.length
        );
      }
      return false;
    }).length === graphData.metrics.filter((query) => query.result).length
  );
};

/**
 * Checks that element that triggered event is located on cluster health check dashboard
 * @param {HTMLElement}  element to check against
 * @returns {boolean}
 */
const isClusterHealthBoard = () => (document.body.dataset.page || '').includes(':clusters:show');

/* eslint-disable @gitlab/require-i18n-strings */
/**
 * Tracks snowplow event when user generates link to metric chart
 * @param {String}  chart link that will be sent as a property for the event
 * @return {Object} config object for event tracking
 */
export const generateLinkToChartOptions = (chartLink) => {
  const isCLusterHealthBoard = isClusterHealthBoard();

  const category = isCLusterHealthBoard
    ? 'Cluster Monitoring'
    : 'Incident Management::Embedded metrics';
  const action = isCLusterHealthBoard
    ? 'generate_link_to_cluster_metric_chart'
    : 'generate_link_to_metrics_chart';

  return { category, action, label: 'Chart link', property: chartLink };
};

/**
 * Tracks snowplow event when user downloads CSV of cluster metric
 * @param {String}  chart title that will be sent as a property for the event
 * @return {Object} config object for event tracking
 */
export const downloadCSVOptions = (title) => {
  const isCLusterHealthBoard = isClusterHealthBoard();

  const category = isCLusterHealthBoard
    ? 'Cluster Monitoring'
    : 'Incident Management::Embedded metrics';
  const action = isCLusterHealthBoard
    ? 'download_csv_of_cluster_metric_chart'
    : 'download_csv_of_metrics_dashboard_chart';

  return { category, action, label: 'Chart title', property: title };
};
/* eslint-enable @gitlab/require-i18n-strings */

/**
 * Generate options for snowplow to track adding a new metric via the dashboard
 * custom metric modal
 * @return {Object} config object for event tracking
 */
export const getAddMetricTrackingOptions = () => ({
  category: document.body.dataset.page,
  action: 'click_button',
  label: 'add_new_metric',
  property: 'modal',
});

/**
 * This function validates the graph data contains exactly 3 metrics plus
 * value validations from graphDataValidatorForValues.
 * @param {Object} isValues
 * @param {Object} graphData  the graph data response from a prometheus request
 * @returns {boolean} true if the data is valid
 */
export const graphDataValidatorForAnomalyValues = (graphData) => {
  const anomalySeriesCount = 3; // metric, upper, lower
  return (
    graphData.metrics &&
    graphData.metrics.length === anomalySeriesCount &&
    graphDataValidatorForValues(false, graphData)
  );
};

/**
 * Returns a time range from the current URL params
 *
 * @returns {Object|null} The time range defined by the
 * current URL, reading from search query or `window.location.search`.
 * Returns `null` if no parameters form a time range.
 */
export const timeRangeFromUrl = (search = window.location.search) => {
  const params = queryToObject(search, { legacySpacesDecode: true });
  return timeRangeFromParams(params);
};

/**
 * Variable labels are used as names for the dropdowns and also
 * as URL params. Prefixing the name reduces the risk of
 * collision with other URL params
 *
 * @param {String} label label for the template variable
 * @returns {String}
 */
export const addPrefixToLabel = (label) => `${VARIABLE_PREFIX}${label}`;

/**
 * Before the templating variables are passed to the backend the
 * prefix needs to be removed.
 *
 * This method removes the prefix at the beginning of the string.
 *
 * @param {String} label label to remove prefix from
 * @returns {String}
 */
export const removePrefixFromLabel = (label) =>
  (label || '').replace(new RegExp(`^${VARIABLE_PREFIX}`), '');

/**
 * Convert parsed template variables to an object
 * with just keys and values. Prepare the variables
 * to be added to the URL. Keys of the object will
 * have a prefix so that these params can be
 * differentiated from other URL params.
 *
 * @param {Object} variables
 * @returns {Object}
 */
export const convertVariablesForURL = (variables) =>
  variables.reduce((acc, { name, value }) => {
    if (value !== null) {
      acc[addPrefixToLabel(name)] = value;
    }
    return acc;
  }, {});

/**
 * User-defined variables from the URL are extracted. The variables
 * begin with a constant prefix so that it doesn't collide with
 * other URL params.
 *
 * @param {String} search URL
 * @returns {Object} The custom variables defined by the user in the URL
 */
export const templatingVariablesFromUrl = (search = window.location.search) => {
  const params = queryToObject(search, { legacySpacesDecode: true });
  // pick the params with variable prefix
  const paramsWithVars = pickBy(params, (val, key) => key.startsWith(VARIABLE_PREFIX));
  // remove the prefix before storing in the Vuex store
  return mapKeys(paramsWithVars, (val, key) => removePrefixFromLabel(key));
};

/**
 * Update the URL with variables. This usually get triggered when
 * the user interacts with the dynamic input elements in the monitoring
 * dashboard header.
 *
 * @param {Object} variables user defined variables
 */
export const setCustomVariablesFromUrl = (variables) => {
  // prep the variables to append to URL
  const parsedVariables = convertVariablesForURL(variables);
  // update the URL
  updateHistory({
    url: mergeUrlParams(parsedVariables, window.location.href),
    title: document.title,
  });
};

/**
 * Returns a URL with no time range based on the current URL.
 *
 * @param {String} New URL
 */
export const removeTimeRangeParams = (url = window.location.href) =>
  removeParams(timeRangeParamNames, url);

/**
 * Returns a URL for the a different time range based on the
 * current URL and a time range.
 *
 * @param {String} New URL
 */
export const timeRangeToUrl = (timeRange, url = window.location.href) => {
  const toUrl = removeTimeRangeParams(url);
  const params = timeRangeToParams(timeRange);
  return mergeUrlParams(params, toUrl);
};

/**
 * Locates a panel (and its corresponding group) given a (URL) search query. Returns
 * it as payload for the store to set the right expandaded panel.
 *
 * Params used to locate a panel are:
 * - group: Group identifier
 * - title: Panel title
 * - y_label: Panel y_label
 *
 * @param {Object} dashboard - Dashboard reference from the Vuex store
 * @param {String} search - URL location search query
 * @returns {Object} payload - Payload for expanded panel to be displayed
 * @returns {String} payload.group - Group where panel is located
 * @returns {Object} payload.panel - Dashboard panel (graphData) reference
 * @throws Will throw an error if Panel cannot be located.
 */
export const expandedPanelPayloadFromUrl = (dashboard, search = window.location.search) => {
  const params = queryToObject(search, { legacySpacesDecode: true });

  // Search for the panel if any of the search params is identified
  if (params.group || params.title || params.y_label) {
    const panelGroup = dashboard.panelGroups.find(({ group }) => params.group === group);
    const panel = panelGroup.panels.find(
      // eslint-disable-next-line babel/camelcase
      ({ y_label, title }) => y_label === params.y_label && title === params.title,
    );

    if (!panel) {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      throw new Error('Panel could no found by URL parameters.');
    }
    return { group: panelGroup.group, panel };
  }
  return null;
};

/**
 * Convert panel information to a URL for the user to
 * bookmark or share highlighting a specific panel.
 *
 * If no group/panel is set, the dashboard URL is returned.
 *
 * @param {?String} dashboard - Dashboard path, used as identifier for a dashboard
 * @param {?Object} variables - Custom variables that came from the URL
 * @param {?String} group - Group Identifier
 * @param {?Object} panel - Panel object from the dashboard
 * @param {?String} url - Base URL including current search params
 * @returns Dashboard URL which expands a panel (chart)
 */
export const panelToUrl = (
  dashboard = null,
  variables,
  group,
  panel,
  url = window.location.href,
) => {
  const params = {
    dashboard,
    ...variables,
  };

  if (group && panel) {
    params.group = group;
    params.title = panel.title;
    params.y_label = panel.y_label;
  } else {
    // Remove existing parameters if any
    params.group = null;
    params.title = null;
    params.y_label = null;
  }

  return mergeUrlParams(params, url);
};

/**
 * Get the metric value from first data point.
 * Currently only used for bar charts
 *
 * @param {Array} values data points
 * @returns {Number}
 */
const metricValueMapper = (values) => values[0]?.[1];

/**
 * Get the metric name from metric object
 * Currently only used for bar charts
 * e.g. { handler: '/query' }
 * { method: 'get' }
 *
 * @param {Object} metric metric object
 * @returns {String}
 */
const metricNameMapper = (metric) => Object.values(metric)?.[0];

/**
 * Parse metric object to extract metric value and name in
 * [<metric-value>, <metric-name>] format.
 * Currently only used for bar charts
 *
 * @param {Object} param0 metric object
 * @returns {Array}
 */
const resultMapper = ({ metric, values = [] }) => [
  metricValueMapper(values),
  metricNameMapper(metric),
];

/**
 * Bar charts graph data parser to massage data from
 * backend to a format acceptable by bar charts component
 * in GitLab UI
 *
 * e.g.
 * {
 *   SLO: [
 *      [98, 'api'],
 *      [99, 'web'],
 *      [99, 'database']
 *   ]
 * }
 *
 * @param {Array} data series information
 * @returns {Object}
 */
export const barChartsDataParser = (data = []) =>
  data?.reduce(
    (acc, { result = [], label }) => ({
      ...acc,
      [label]: result.map(resultMapper),
    }),
    {},
  );
