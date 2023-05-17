export const PROMETHEUS_TIMEOUT = 120000; // TWO_MINUTES

export const dashboardEmptyStates = {
  GETTING_STARTED: 'gettingStarted',
  LOADING: 'loading',
  NO_DATA: 'noData',
  UNABLE_TO_CONNECT: 'unableToConnect',
};

/**
 * States and error states in Prometheus Queries (PromQL) for metrics
 */
export const metricStates = {
  /**
   * Metric data is available
   */
  OK: 'OK',

  /**
   * Metric data is being fetched for the first time.
   *
   * Not used during data refresh, if data is available in
   * the metric, the recommneded state is OK.
   */
  LOADING: 'LOADING',

  /**
   * Connection timed out to prometheus server
   * the timeout is set to PROMETHEUS_TIMEOUT
   *
   */
  TIMEOUT: 'TIMEOUT',

  /**
   * The prometheus server replies with an empty data set
   */
  NO_DATA: 'NO_DATA',

  /**
   * The prometheus server cannot be reached
   */
  CONNECTION_FAILED: 'CONNECTION_FAILED',

  /**
   * The prometheus server was reached but it cannot process
   * the query. This can happen for several reasons:
   * - PromQL syntax is incorrect
   * - An operator is not supported
   */
  BAD_QUERY: 'BAD_QUERY',

  /**
   * No specific reason found for error
   */
  UNKNOWN_ERROR: 'UNKNOWN_ERROR',
};

/**
 * Supported panel types in dashboards, values of `panel.type`.
 *
 * Values should not be changed as they correspond to
 * values in users the `.yml` dashboard definition.
 */
export const panelTypes = {
  /**
   * Area Chart
   *
   * Time Series chart with an area
   */
  AREA_CHART: 'area-chart',
  /**
   * Line Chart
   *
   * Time Series chart with a line
   */
  LINE_CHART: 'line-chart',
  /**
   * Anomaly Chart
   *
   * Time Series chart with 3 metrics
   */
  ANOMALY_CHART: 'anomaly-chart',
  /**
   * Single Stat
   *
   * Single data point visualization
   */
  SINGLE_STAT: 'single-stat',
  /**
   * Gauge
   */
  GAUGE_CHART: 'gauge',
  /**
   * Heatmap
   */
  HEATMAP: 'heatmap',
  /**
   * Bar chart
   */
  BAR: 'bar',
  /**
   * Column chart
   */
  COLUMN: 'column',
  /**
   * Stacked column chart
   */
  STACKED_COLUMN: 'stacked-column',
};

export const sidebarAnimationDuration = 300; // milliseconds.
export const chartHeight = 300;

export const graphTypes = {
  annotationsData: 'scatter',
};

export const symbolSizes = {
  anomaly: 8,
  default: 14,
};

export const areaOpacityValues = {
  default: 0.2,
};

export const colorValues = {
  primaryColor: '#1f78d1', // $blue-500 (see variables.scss)
  anomalySymbol: '#db3b21',
  anomalyAreaColor: '#1f78d1',
};

export const lineTypes = {
  default: 'solid',
};

export const lineWidths = {
  default: 2,
};

/**
 * User-defined links can be passed in dashboard yml file.
 * These are the supported type of links.
 */
export const linkTypes = {
  GRAFANA: 'grafana',
};

/**
 * These are the supported values for the GitLab-UI
 * chart legend layout.
 *
 * Currently defined in
 * https://gitlab.com/gitlab-org/gitlab-ui/-/blob/main/src/utils/charts/constants.js
 *
 */
export const legendLayoutTypes = {
  inline: 'inline',
  table: 'table',
};

/**
 * These Vuex store properties are allowed to be
 * replaced dynamically after component has been created
 * and initial state has been set.
 *
 * Currently used in `receiveMetricsDashboardSuccess` action.
 */
export const endpointKeys = [
  'deploymentsEndpoint',
  'dashboardEndpoint',
  'dashboardsEndpoint',
  'currentDashboard',
  'projectPath',
];

/**
 * These Vuex store properties are set as soon as the
 * dashboard component has been created. The values are
 * passed as data-* attributes and received by dashboard
 * as Vue props.
 */
export const initialStateKeys = [...endpointKeys, 'currentEnvironmentName'];

/**
 * Constant to indicate if a metric exists in the database
 */
export const NOT_IN_DB_PREFIX = 'NO_DB';

/**
 * graphQL environments API value for active environments.
 * Used as a value for the 'states' query filter
 */
export const ENVIRONMENT_AVAILABLE_STATE = 'available';

/**
 * As of %12.10, the svg icon library does not have an annotation
 * arrow icon yet. In order to deliver annotations feature, the icon
 * is hard coded until the icon is added. The below issue is
 * to track the icon.
 *
 * https://gitlab.com/gitlab-org/gitlab-svgs/-/issues/118
 *
 * Once the icon is merged this can be removed.
 * https://gitlab.com/gitlab-org/gitlab/-/issues/214540
 */
export const annotationsSymbolIcon = 'path://m5 229 5 8h-10z';

/**
 * As of %12.10, dashboard path is required to create annotation.
 * The FE gets the dashboard name from the URL params. It is not
 * ideal to store the path this way but there is no other way to
 * get this path unless annotations fetch is delayed. This could
 * potentially be removed and have the backend send this to the FE.
 *
 * This technical debt is being tracked here
 * https://gitlab.com/gitlab-org/gitlab/-/issues/214671
 */
export const OVERVIEW_DASHBOARD_PATH = 'config/prometheus/common_metrics.yml';

/**
 * GitLab provide metrics dashboards that are available to a user once
 * the Prometheus managed app has been installed, without any extra setup
 * required. These "out of the box" dashboards are defined under the
 * `config/prometheus` path.
 */
export const OUT_OF_THE_BOX_DASHBOARDS_PATH_PREFIX = 'config/prometheus/';

/**
 * Dashboard yml files support custom user-defined variables that
 * are rendered as input elements in the monitoring dashboard.
 * These values can be edited by the user and are passed on to the
 * the backend and eventually to Prometheus API proxy.
 *
 * As of 13.0, the supported types are:
 * simple custom -> dropdown elements
 * advanced custom -> dropdown elements
 * text -> text input elements
 *
 * Custom variables have a simple and a advanced variant.
 */
export const VARIABLE_TYPES = {
  custom: 'custom',
  text: 'text',
  metric_label_values: 'metric_label_values',
};

/**
 * The names of templating variables defined in the dashboard yml
 * file are prefixed with a constant so that it doesn't collide with
 * other URL params that the monitoring dashboard relies on for
 * features like panel fullscreen etc.
 *
 * The prefix is added before it is appended to the URL and removed
 * before passing the data to the backend.
 */
export const VARIABLE_PREFIX = 'var-';

export const thresholdModeTypes = {
  ABSOLUTE: 'absolute',
  PERCENTAGE: 'percentage',
};
