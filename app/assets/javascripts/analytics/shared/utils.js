import { flatten } from 'lodash';
import dateFormat from '~/lib/dateformat';
import { SECONDS_IN_DAY } from '~/lib/utils/datetime_utility';
import { slugify } from '~/lib/utils/text_utility';
import { joinPaths } from '~/lib/utils/url_utility';
import { urlQueryToFilter } from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import {
  dateFormats,
  FLOW_METRICS,
  MAX_METRIC_PRECISION,
  UNITS,
  VALUE_STREAM_METRIC_DISPLAY_UNITS,
  VALUE_STREAM_METRIC_TILE_METADATA,
} from './constants';

export const filterBySearchTerm = (data = [], searchTerm = '', filterByKey = 'name') => {
  if (!searchTerm?.length) return data;
  return data.filter((item) => item[filterByKey].toLowerCase().includes(searchTerm.toLowerCase()));
};

export const toYmd = (date) => dateFormat(date, dateFormats.isoDate);

/**
 * Takes a url and extracts query parameters used for the shared
 * filter bar
 *
 * @param {string} url The URL to extract query parameters from
 * @returns {Object}
 */
export const extractFilterQueryParameters = (url = '') => {
  const {
    source_branch_name: selectedSourceBranch = null,
    target_branch_name: selectedTargetBranch = null,
    author_username: selectedAuthor = null,
    milestone_title: selectedMilestone = null,
    assignee_username: selectedAssigneeList = [],
    label_name: selectedLabelList = [],
  } = urlQueryToFilter(url);

  return {
    selectedSourceBranch,
    selectedTargetBranch,
    selectedAuthor,
    selectedMilestone,
    selectedAssigneeList,
    selectedLabelList,
  };
};

/**
 * Takes a url and extracts sorting and pagination query parameters into an object
 *
 * @param {string} url The URL to extract query parameters from
 * @returns {Object}
 */
export const extractPaginationQueryParameters = (url = '') => {
  const { sort, direction, page } = urlQueryToFilter(url);
  return {
    sort: sort?.value || null,
    direction: direction?.value || null,
    page: page?.value || null,
  };
};

export const getDataZoomOption = ({
  totalItems = 0,
  maxItemsPerPage = 40,
  dataZoom = [{ type: 'slider', bottom: 10, start: 0 }],
}) => {
  if (totalItems <= maxItemsPerPage) {
    return {};
  }

  const intervalEnd = Math.ceil((maxItemsPerPage / totalItems) * 100);

  return dataZoom.map((item) => {
    return {
      ...item,
      end: intervalEnd,
    };
  });
};

export const removeFlash = (type = 'alert') => {
  // flash-warning don't have dismiss button.
  document.querySelector(`.flash-${type} .js-close`)?.click();
};

/**
 * Prepares metric data to be rendered in the metric_card component
 *
 * @param {MetricData[]} data - The metric data to be rendered
 * @param {Object} popoverContent - Key value pair of data to display in the popover
 * @returns {TransformedMetricData[]} An array of metrics ready to render in the metric_card
 */
export const prepareTimeMetricsData = (data = [], popoverContent = {}) =>
  data.map(({ title: label, identifier, ...rest }) => {
    const metricIdentifier = identifier || slugify(label);
    return {
      ...rest,
      label,
      identifier: metricIdentifier,
      description: popoverContent[metricIdentifier]?.description || '',
    };
  });

const requestData = ({ request, endpoint, requestPath, params, name }) => {
  return request({ endpoint, params, requestPath })
    .then(({ data }) => data)
    .catch(() => {
      throw new Error(name);
    });
};

/**
 * Takes a configuration array of metrics requests (key metrics and DORA) and returns
 * a flat array of all the responses. Different metrics are retrieved from different endpoints
 * additionally we only support certain metrics for FOSS users.
 *
 * @param {Array} requests - array of metric api requests to be made
 * @param {String} requestPath - path for the group / project we are requesting
 * @param {Object} params - optional parameters to filter, including `created_after` and `created_before` dates
 * @returns a flat array of metrics
 */
export const fetchMetricsData = (requests = [], requestPath, params) => {
  const promises = requests.map((r) => requestData({ ...r, requestPath, params }));
  return Promise.all(promises).then((responses) =>
    prepareTimeMetricsData(flatten(responses), VALUE_STREAM_METRIC_TILE_METADATA),
  );
};

/**
 * Formats any valid number as percentage
 *
 * @param {number|string} decimalValue Decimal value between 0 and 1 to be converted to a percentage
 * @param {number} precision The number of decimal places to round to
 *
 * @returns {string} Returns a formatted string multiplied by 100
 */
export const formatAsPercentageWithoutSymbol = (decimalValue = 0, precision = 1) => {
  const parsed = Number.isNaN(Number(decimalValue)) ? 0 : decimalValue;
  return (parsed * 100).toFixed(precision);
};

/**
 * Converts a time in seconds to number of days, with variable precision
 *
 * @param {Number} seconds Time in seconds
 * @param {Number} precision Specifies the number of digits after the decimal
 *
 * @returns {Float} The number of days
 */
export const secondsToDays = (seconds, precision = 1) =>
  (seconds / SECONDS_IN_DAY).toFixed(precision);

export const scaledValueForDisplay = (value, units, precision = MAX_METRIC_PRECISION) => {
  switch (units) {
    case UNITS.PERCENT:
      return formatAsPercentageWithoutSymbol(value);
    case UNITS.DAYS:
      return secondsToDays(value, precision);
    default:
      return value;
  }
};

const prepareMetricValue = ({ identifier, value, unit }) => {
  // NOTE: the flow metrics graphql endpoint returns values already scaled for display
  if (!value) {
    // ensures we return `-` for 0/null etc
    return '-';
  }
  return Object.values(FLOW_METRICS).includes(identifier)
    ? value
    : scaledValueForDisplay(value, unit);
};

/**
 * Prepares metric data to be rendered in the metric_tile component
 *
 * @param {MetricData[]} data - The metric data to be rendered
 * @returns {TransformedMetricData[]} An array of metrics ready to render in the metric_tile
 */
export const rawMetricToMetricTile = (metric) => {
  const { identifier, value, ...metricRest } = metric;
  const { unit, label, ...metadataRest } = VALUE_STREAM_METRIC_TILE_METADATA[identifier];
  return {
    ...metadataRest,
    ...metricRest,
    title: label,
    identifier,
    label,
    unit: VALUE_STREAM_METRIC_DISPLAY_UNITS[unit],
    value: prepareMetricValue({ value, unit, identifier }),
  };
};

/**
 * Generates a URL link to the VSD dashboard based on the group
 * and project paths passed into the method.
 *
 * @param {String} groupPath - Path of the specified group
 * @returns a URL or blank string if there is no groupPath set
 */
export const generateValueStreamsDashboardLink = (namespacePath) => {
  if (namespacePath.length) {
    const dashboardsSlug = '/-/analytics/dashboards/value_streams_dashboard';
    const segments = [gon.relative_url_root || '', '/', namespacePath, dashboardsSlug];
    return joinPaths(...segments);
  }
  return '';
};

/**
 * Extracts the relevant feature and license flags needed for VSA
 *
 * @param {Object} gon the global `window.gon` object populated when the page loads
 * @returns an object containing the extracted feature flags and their boolean status
 */
export const extractVSAFeaturesFromGON = () => ({
  // licensed feature toggles
  cycleAnalyticsForGroups: Boolean(gon?.licensed_features?.cycleAnalyticsForGroups),
  cycleAnalyticsForProjects: Boolean(gon?.licensed_features?.cycleAnalyticsForProjects),
  groupLevelAnalyticsDashboard: Boolean(gon?.licensed_features?.groupLevelAnalyticsDashboard),
});

/**
 * Takes a raw GraphQL response which could contain data for a group or project namespace,
 * and returns the data for the namespace which is present in the response.
 *
 * @param {Object} params
 * @param {string} params.resultKey - The data to be extracted from the namespace.
 * @param {Object} params.result
 * @param {Object} params.result.data
 * @param {Object} params.result.data.group - The group GraphQL response.
 * @param {Object} params.result.data.project - The project GraphQL response.
 * @returns {Object} The data extracted from either group[resultKey] or project[resultKey].
 */
export const extractQueryResponseFromNamespace = ({ result, resultKey }) => {
  const { group = null, project = null } = result.data;
  if (group || project) {
    const namespace = group ?? project;
    return namespace[resultKey] || {};
  }
  return {};
};
