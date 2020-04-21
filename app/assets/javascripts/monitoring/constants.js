export const PROMETHEUS_TIMEOUT = 120000; // TWO_MINUTES

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

export const dateFormats = {
  timeOfDay: 'h:MM TT',
  default: 'dd mmm yyyy, h:MMTT',
};

/**
 * These Vuex store properties are allowed to be
 * replaced dynamically after component has been created
 * and initial state has been set.
 *
 * Currently used in `receiveMetricsDashboardSuccess` action.
 */
export const endpointKeys = [
  'metricsEndpoint',
  'deploymentsEndpoint',
  'dashboardEndpoint',
  'dashboardsEndpoint',
  'currentDashboard',
  'projectPath',
  'logsPath',
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
export const DEFAULT_DASHBOARD_PATH = 'config/prometheus/common_metrics.yml';

export const OPERATORS = {
  greaterThan: '>',
  equalTo: '==',
  lessThan: '<',
};
