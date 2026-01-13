import { queryToObject, updateHistory, mergeUrlParams } from '~/lib/utils/url_utility';

const PARAM_KEY_SOURCE = 'source';
const PARAM_KEY_BRANCH = 'branch';
const PARAM_KEY_DATE_RANGE = 'time';
const PARAM_KEY_JOB_NAME = 'job';

/**
 * Returns an object that represents parameters in the URL
 *
 * @param {Object} params - URL query string, defaults to the current `window.location.search`
 * @param {Object} params - Default values, so URL does not have to add redundant values
 */
export const paramsFromQuery = (searchString = window.location.search, defaultParams = {}) => {
  const query = queryToObject(searchString);
  return {
    source: query[PARAM_KEY_SOURCE] || defaultParams.source,
    branch: query[PARAM_KEY_BRANCH] || defaultParams.branch,
    dateRange: query[PARAM_KEY_DATE_RANGE] || defaultParams.dateRange,
    jobName: query[PARAM_KEY_JOB_NAME] || defaultParams.jobName,
  };
};

/**
 * Updates the browser URL bar with some parameters
 *
 * @param {Object} params - Current params to represent in the URL
 * @param {Object} params - Default values, so URL is not updated with redundant values
 */
export const updateQueryHistory = (params, defaultParams = {}) => {
  const { source, branch, dateRange, jobName } = params;
  const query = {
    [PARAM_KEY_SOURCE]: source === defaultParams.source ? null : source,
    [PARAM_KEY_BRANCH]: branch === defaultParams.branch ? null : branch,
    [PARAM_KEY_DATE_RANGE]: dateRange === defaultParams.dateRange ? null : dateRange,
    [PARAM_KEY_JOB_NAME]: jobName === defaultParams.jobName ? null : jobName,
  };
  updateHistory({
    url: mergeUrlParams(query, window.location.href, { sort: true }),
  });
};
