import dateFormat from '~/lib/dateformat';
import { SECONDS_IN_DAY } from '~/lib/utils/datetime_utility';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
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
 * Generates a URL link to the VSD dashboard based on the
 * namespace path passed into the method.
 *
 * @param {String} namespacePath - Path of the specified namespace
 * @param {Boolean} isProjectNamespace
 * @returns a URL or blank string if there is no namespacePath set
 */
export const generateValueStreamsDashboardLink = (
  namespacePath = null,
  isProjectNamespace = false,
) => {
  if (!namespacePath) return '';

  const dashboardsSlug = '/-/analytics/dashboards/value_streams_dashboard';
  const formattedNamespacePath = isProjectNamespace ? namespacePath : `groups/${namespacePath}`;
  const segments = [gon.relative_url_root || '', '/', formattedNamespacePath, dashboardsSlug];

  return joinPaths(...segments);
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

/**
 * Takes the raw snake_case query parameters and extracts + converts the relevant values
 * for the overview metrics component
 * @param {Object} params - Object containing the supported query parameters
 * @param {Date} params.created_before
 * @param {Date} params.created_after
 * @param {string} params.author_username
 * @param {string} params.milestone_title
 * @param {Array} params.label_name
 * @param {Array} params.assignee_username
 *
 * @returns {Object} CamelCased parameter names
 */
export const overviewMetricsRequestParams = (params = {}) => {
  const {
    createdAfter: startDate,
    createdBefore: endDate,
    labelName: labelNames,
    assigneeUsername: assigneeUsernames,
    ...rest
  } = convertObjectPropsToCamelCase(params);
  return {
    startDate,
    endDate,
    labelNames,
    assigneeUsernames,
    ...rest,
  };
};
