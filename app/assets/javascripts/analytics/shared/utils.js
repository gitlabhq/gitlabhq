import { flatten } from 'lodash';
import dateFormat from '~/lib/dateformat';
import { slugify } from '~/lib/utils/text_utility';
import { joinPaths } from '~/lib/utils/url_utility';
import { urlQueryToFilter } from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import { dateFormats, METRICS_POPOVER_CONTENT } from './constants';

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
    prepareTimeMetricsData(flatten(responses), METRICS_POPOVER_CONTENT),
  );
};

/**
 * Generates a URL link to the VSD dashboard based on the group
 * and project paths passed into the method.
 *
 * @param {String} groupPath - Path of the specified group
 * @param {Array} projectPaths - Array of project paths to include in the `query` parameter
 * @returns a URL or blank string if there is no groupPath set
 */
export const generateValueStreamsDashboardLink = (namespacePath, projectPaths = []) => {
  if (namespacePath.length) {
    const query = projectPaths.length ? `?query=${projectPaths.join(',')}` : '';
    const dashboardsSlug = '/-/analytics/dashboards/value_streams_dashboard';
    const segments = [gon.relative_url_root || '', '/', namespacePath, dashboardsSlug];
    return joinPaths(...segments).concat(query);
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
  // feature flags
  vsaGroupAndProjectParity: Boolean(gon?.features?.vsaGroupAndProjectParity),
});
