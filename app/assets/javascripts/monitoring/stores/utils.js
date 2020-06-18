import { slugify } from '~/lib/utils/text_utility';
import createGqClient, { fetchPolicies } from '~/lib/graphql';
import { SUPPORTED_FORMATS } from '~/lib/utils/unit_format';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { parseTemplatingVariables } from './variable_mapping';
import { NOT_IN_DB_PREFIX, linkTypes } from '../constants';
import { DATETIME_RANGE_TYPES } from '~/lib/utils/constants';
import { timeRangeToParams, getRangeType } from '~/lib/utils/datetime_range';
import { isSafeURL, mergeUrlParams } from '~/lib/utils/url_utility';

export const gqClient = createGqClient(
  {},
  {
    fetchPolicy: fetchPolicies.NO_CACHE,
  },
);

/**
 * Metrics loaded from project-defined dashboards do not have a metric_id.
 * This method creates a unique ID combining metric_id and id, if either is present.
 * This is hopefully a temporary solution until BE processes metrics before passing to FE
 *
 * Related:
 * https://gitlab.com/gitlab-org/gitlab/-/issues/28241
 * https://gitlab.com/gitlab-org/gitlab/-/merge_requests/27447
 *
 * @param {Object} metric - metric
 * @param {Number} metric.metric_id - Database metric id
 * @param {String} metric.id - User-defined identifier
 * @returns {Object} - normalized metric with a uniqueID
 */
// eslint-disable-next-line babel/camelcase
export const uniqMetricsId = ({ metric_id, id }) => `${metric_id || NOT_IN_DB_PREFIX}_${id}`;

/**
 * Project path has a leading slash that doesn't work well
 * with project full path resolver here
 * https://gitlab.com/gitlab-org/gitlab/blob/5cad4bd721ab91305af4505b2abc92b36a56ad6b/app/graphql/resolvers/full_path_resolver.rb#L10
 *
 * @param {String} str String with leading slash
 * @returns {String}
 */
export const removeLeadingSlash = str => (str || '').replace(/^\/+/, '');

/**
 * GraphQL environments API returns only id and name.
 * For the environments dropdown we need metrics_path.
 * This method parses the results and add neccessart attrs
 *
 * @param {Array} response Environments API result
 * @param {String} projectPath Current project path
 * @returns {Array}
 */
export const parseEnvironmentsResponse = (response = [], projectPath) =>
  (response || []).map(env => {
    const id = getIdFromGraphQLId(env.id);
    return {
      ...env,
      id,
      metrics_path: `${projectPath}/environments/${id}/metrics`,
    };
  });

/**
 * Annotation API returns time in UTC. This method
 * converts time to local time.
 *
 * startingAt always exists but endingAt does not.
 * If endingAt does not exist, a threshold line is
 * drawn.
 *
 * If endingAt exists, a threshold range is drawn.
 * But this is not supported as of %12.10
 *
 * @param {Array} response annotations response
 * @returns {Array} parsed responses
 */
export const parseAnnotationsResponse = response => {
  if (!response) {
    return [];
  }
  return response.map(annotation => ({
    ...annotation,
    startingAt: new Date(annotation.startingAt),
    endingAt: annotation.endingAt ? new Date(annotation.endingAt) : null,
  }));
};

/**
 * Maps metrics to its view model
 *
 * This function difers from other in that is maps all
 * non-define properties as-is to the object. This is not
 * advisable as it could lead to unexpected side-effects.
 *
 * Related issue:
 * https://gitlab.com/gitlab-org/gitlab/issues/207198
 *
 * @param {Array} metrics - Array of prometheus metrics
 * @returns {Object}
 */
const mapToMetricsViewModel = metrics =>
  metrics.map(({ label, id, metric_id, query_range, prometheus_endpoint_path, ...metric }) => ({
    label,
    queryRange: query_range,
    prometheusEndpointPath: prometheus_endpoint_path,
    metricId: uniqMetricsId({ metric_id, id }),

    // metric data
    loading: false,
    result: null,
    state: null,

    ...metric,
  }));

/**
 * Maps X-axis view model
 *
 * @param {Object} axis
 */
const mapXAxisToViewModel = ({ name = '' }) => ({ name });

/**
 * Maps Y-axis view model
 *
 * Defaults to a 2 digit precision and `engineering` format. It only allows
 * formats in the SUPPORTED_FORMATS array.
 *
 * @param {Object} axis
 */
const mapYAxisToViewModel = ({
  name = '',
  format = SUPPORTED_FORMATS.engineering,
  precision = 2,
}) => {
  return {
    name,
    format: SUPPORTED_FORMATS[format] || SUPPORTED_FORMATS.engineering,
    precision,
  };
};

/**
 * Maps a link to its view model, expects an url and
 * (optionally) a title.
 *
 * Unsafe URLs are ignored.
 *
 * @param {Object} Link
 * @returns {Object} Link object with a `title`, `url` and `type`
 *
 */
const mapLinksToViewModel = ({ url = null, title = '', type } = {}) => {
  return {
    title: title || String(url),
    type,
    url: url && isSafeURL(url) ? String(url) : '#',
  };
};

/**
 * Maps a metrics panel to its view model
 *
 * @param {Object} panel - Metrics panel
 * @returns {Object}
 */
const mapPanelToViewModel = ({
  id = null,
  title = '',
  type,
  x_axis = {},
  x_label,
  y_label,
  y_axis = {},
  metrics = [],
  links = [],
  max_value,
}) => {
  // Both `x_axis.name` and `x_label` are supported for now
  // https://gitlab.com/gitlab-org/gitlab/issues/210521
  const xAxis = mapXAxisToViewModel({ name: x_label, ...x_axis }); // eslint-disable-line babel/camelcase

  // Both `y_axis.name` and `y_label` are supported for now
  // https://gitlab.com/gitlab-org/gitlab/issues/208385
  const yAxis = mapYAxisToViewModel({ name: y_label, ...y_axis }); // eslint-disable-line babel/camelcase

  return {
    id,
    title,
    type,
    xLabel: xAxis.name,
    y_label: yAxis.name, // Changing y_label to yLabel is pending https://gitlab.com/gitlab-org/gitlab/issues/207198
    yAxis,
    xAxis,
    maxValue: max_value,
    links: links.map(mapLinksToViewModel),
    metrics: mapToMetricsViewModel(metrics),
  };
};

/**
 * Maps a metrics panel group to its view model
 *
 * @param {Object} panelGroup - Panel Group
 * @returns {Object}
 */
const mapToPanelGroupViewModel = ({ group = '', panels = [] }, i) => {
  return {
    key: `${slugify(group || 'default')}-${i}`,
    group,
    panels: panels.map(mapPanelToViewModel),
  };
};

/**
 * Convert dashboard time range to Grafana
 * dashboards time range.
 *
 * @param {Object} timeRange
 * @returns {Object}
 */
export const convertToGrafanaTimeRange = timeRange => {
  const timeRangeType = getRangeType(timeRange);
  if (timeRangeType === DATETIME_RANGE_TYPES.fixed) {
    return {
      from: new Date(timeRange.start).getTime(),
      to: new Date(timeRange.end).getTime(),
    };
  } else if (timeRangeType === DATETIME_RANGE_TYPES.rolling) {
    const { seconds } = timeRange.duration;
    return {
      from: `now-${seconds}s`,
      to: 'now',
    };
  }
  // fallback to returning the time range as is
  return timeRange;
};

/**
 * Convert dashboard time ranges to other supported
 * link formats.
 *
 * @param {Object} timeRange metrics dashboard time range
 * @param {String} type type of link
 * @returns {String}
 */
export const convertTimeRanges = (timeRange, type) => {
  if (type === linkTypes.GRAFANA) {
    return convertToGrafanaTimeRange(timeRange);
  }
  return timeRangeToParams(timeRange);
};

/**
 * Adds dashboard-related metadata to the user-defined links.
 *
 * As of %13.1, metadata only includes timeRange but in the
 * future more info will be added to the links.
 *
 * @param {Object} metadata
 * @returns {Function}
 */
export const addDashboardMetaDataToLink = metadata => link => {
  let modifiedLink = { ...link };
  if (metadata.timeRange) {
    modifiedLink = {
      ...modifiedLink,
      url: mergeUrlParams(convertTimeRanges(metadata.timeRange, link.type), link.url),
    };
  }
  return modifiedLink;
};

/**
 * Maps a dashboard json object to its view model
 *
 * @param {Object} dashboard - Dashboard object
 * @param {String} dashboard.dashboard - Dashboard name object
 * @param {Array} dashboard.panel_groups - Panel groups array
 * @returns {Object}
 */
export const mapToDashboardViewModel = ({
  dashboard = '',
  templating = {},
  links = [],
  panel_groups = [],
}) => {
  return {
    dashboard,
    variables: parseTemplatingVariables(templating),
    links: links.map(mapLinksToViewModel),
    panelGroups: panel_groups.map(mapToPanelGroupViewModel),
  };
};

/**
 * Processes a single Range vector, part of the result
 * of type `matrix` in the form:
 *
 * {
 *   "metric": { "<label_name>": "<label_value>", ... },
 *   "values": [ [ <unix_time>, "<sample_value>" ], ... ]
 * },
 *
 * See https://prometheus.io/docs/prometheus/latest/querying/api/#range-vectors
 *
 * @param {*} timeSeries
 */
export const normalizeQueryResult = timeSeries => {
  let normalizedResult = {};

  if (timeSeries.values) {
    normalizedResult = {
      ...timeSeries,
      values: timeSeries.values.map(([timestamp, value]) => [
        new Date(timestamp * 1000).toISOString(),
        Number(value),
      ]),
    };
    // Check result for empty data
    normalizedResult.values = normalizedResult.values.filter(series => {
      const hasValue = d => !Number.isNaN(d[1]) && (d[1] !== null || d[1] !== undefined);
      return series.find(hasValue);
    });
  } else if (timeSeries.value) {
    normalizedResult = {
      ...timeSeries,
      value: [new Date(timeSeries.value[0] * 1000).toISOString(), Number(timeSeries.value[1])],
    };
  }

  return normalizedResult;
};

/**
 * Custom variables defined in the dashboard yml file are
 * eventually passed over the wire to the backend Prometheus
 * API proxy.
 *
 * This method adds a prefix to the URL param keys so that
 * the backend can differential these variables from the other
 * variables.
 *
 * This is currently only used by getters/getCustomVariablesParams
 *
 * @param {String} key Variable key that needs to be prefixed
 * @returns {String}
 */
export const addPrefixToCustomVariableParams = key => `variables[${key}]`;
