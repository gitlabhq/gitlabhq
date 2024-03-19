import { isEmpty } from 'lodash';
import { queryToObject, setUrlParams } from '~/lib/utils/url_utility';
import {
  filterToQueryObject,
  processFilters,
  urlQueryToFilter,
  prepareTokens,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import { parseBoolean } from '~/lib/utils/common_utils';
import {
  PARAM_KEY_PAUSED,
  PARAM_KEY_STATUS,
  PARAM_KEY_RUNNER_TYPE,
  PARAM_KEY_TAG,
  PARAM_KEY_VERSION,
  PARAM_KEY_SEARCH,
  PARAM_KEY_CREATOR,
  PARAM_KEY_MEMBERSHIP,
  PARAM_KEY_SORT,
  PARAM_KEY_AFTER,
  PARAM_KEY_BEFORE,
  DEFAULT_SORT,
  DEFAULT_MEMBERSHIP,
  RUNNER_PAGE_SIZE,
} from './constants';
import { getPaginationVariables } from './utils';

/**
 * The filters and sorting of the runners are built around
 * an object called "search" that contains the current state
 * of search in the UI. For example:
 *
 * ```
 * const search = {
 *   // The current tab
 *   runnerType: 'INSTANCE_TYPE',
 *
 *   // Filters in the search bar
 *   filters: [
 *     { type: 'status', value: { data: 'ACTIVE', operator: '=' } },
 *     { type: 'filtered-search-term', value: { data: '' } },
 *   ],
 *
 *   // Current sorting value
 *   sort: 'CREATED_DESC',
 *
 *   // Pagination information
 *   pagination: { "after": "..." },
 * };
 * ```
 *
 * An object in this format can be used to generate URLs
 * with the search parameters or by runner components
 * a input using a v-model.
 *
 * @module runner_search_utils
 */

/**
 * Validates a search value
 * @param {Object} search
 * @returns {boolean} True if the value follows the search format.
 */
export const searchValidator = ({ runnerType, membership, filters, sort }) => {
  return (
    (runnerType === null || typeof runnerType === 'string') &&
    (membership === null || typeof membership === 'string') &&
    Array.isArray(filters) &&
    typeof sort === 'string'
  );
};

const getPaginationFromParams = (params) => {
  return {
    after: params[PARAM_KEY_AFTER],
    before: params[PARAM_KEY_BEFORE],
  };
};

// Outdated URL parameters
const STATUS_ACTIVE = 'ACTIVE';
const STATUS_PAUSED = 'PAUSED';
const PARAM_KEY_PAGE = 'page';

/**
 * Replaces params into a URL
 *
 * @param {String} url - Original URL
 * @param {Object} params - Query parameters to update
 * @returns Updated URL
 */
const updateUrlParams = (url, params = {}) => {
  return setUrlParams(params, url, false, true, true);
};

const outdatedStatusParams = (status) => {
  if (status === STATUS_ACTIVE) {
    return {
      [PARAM_KEY_PAUSED]: ['false'],
      [PARAM_KEY_STATUS]: [], // Important! clear PARAM_KEY_STATUS to avoid a redirection loop!
    };
  }
  if (status === STATUS_PAUSED) {
    return {
      [PARAM_KEY_PAUSED]: ['true'],
      [PARAM_KEY_STATUS]: [], // Important! clear PARAM_KEY_STATUS to avoid a redirection loop!
    };
  }
  return {};
};

/**
 * Returns an updated URL for old (or deprecated) admin runner URLs.
 *
 * Use for redirecting users to currently used URLs.
 *
 * @param {String?} URL
 * @returns Updated URL if outdated, `null` otherwise
 */
export const updateOutdatedUrl = (url = window.location.href) => {
  const urlObj = new URL(url);
  const query = urlObj.search;
  const params = queryToObject(query, { gatherArrays: true });

  // Remove `page` completely, not needed for keyset pagination
  const pageParams = PARAM_KEY_PAGE in params ? { [PARAM_KEY_PAGE]: null } : {};

  const status = params[PARAM_KEY_STATUS]?.[0];
  const redirectParams = {
    // Replace paused status (active, paused) with a paused flag
    ...outdatedStatusParams(status),
    ...pageParams,
  };

  if (!isEmpty(redirectParams)) {
    return updateUrlParams(url, redirectParams);
  }
  return null;
};

/**
 * Takes a URL query and transforms it into a "search" object
 * @param {String?} query
 * @returns {Object} A search object
 */
export const fromUrlQueryToSearch = (query = window.location.search) => {
  const params = queryToObject(query, { gatherArrays: true });
  const runnerType = params[PARAM_KEY_RUNNER_TYPE]?.[0] || null;
  const membership = params[PARAM_KEY_MEMBERSHIP]?.[0] || null;

  return {
    runnerType,
    membership: membership || DEFAULT_MEMBERSHIP,
    filters: prepareTokens(
      urlQueryToFilter(query, {
        filterNamesAllowList: [
          PARAM_KEY_PAUSED,
          PARAM_KEY_STATUS,
          PARAM_KEY_TAG,
          PARAM_KEY_VERSION,
          PARAM_KEY_CREATOR,
        ],
        filteredSearchTermKey: PARAM_KEY_SEARCH,
      }),
    ),
    sort: params[PARAM_KEY_SORT] || DEFAULT_SORT,
    pagination: getPaginationFromParams(params),
  };
};

/**
 * Takes a "search" object and transforms it into a URL.
 *
 * @param {Object} search
 * @param {String} url
 * @returns {String} New URL for the page
 */
export const fromSearchToUrl = (
  { runnerType = null, membership = null, filters = [], sort = null, pagination = {} },
  url = window.location.href,
) => {
  const filterParams = {
    // Defaults
    [PARAM_KEY_STATUS]: [],
    [PARAM_KEY_RUNNER_TYPE]: [],
    [PARAM_KEY_MEMBERSHIP]: [],
    [PARAM_KEY_TAG]: [],
    [PARAM_KEY_PAUSED]: [],
    [PARAM_KEY_VERSION]: [],
    [PARAM_KEY_CREATOR]: [],
    // Current filters
    ...filterToQueryObject(processFilters(filters), {
      filteredSearchTermKey: PARAM_KEY_SEARCH,
    }),
  };

  if (runnerType) {
    filterParams[PARAM_KEY_RUNNER_TYPE] = [runnerType];
  }

  if (membership && membership !== DEFAULT_MEMBERSHIP) {
    filterParams[PARAM_KEY_MEMBERSHIP] = [membership];
  }

  if (!filterParams[PARAM_KEY_SEARCH]) {
    filterParams[PARAM_KEY_SEARCH] = null;
  }

  const isDefaultSort = sort !== DEFAULT_SORT;
  const otherParams = {
    // Sorting & Pagination
    [PARAM_KEY_SORT]: isDefaultSort ? sort : null,
    [PARAM_KEY_BEFORE]: pagination?.before || null,
    [PARAM_KEY_AFTER]: pagination?.after || null,
  };

  return setUrlParams({ ...filterParams, ...otherParams }, url, false, true, true);
};

/**
 * Takes a "search" object and transforms it into variables for runner a GraphQL query.
 *
 * @param {Object} search
 * @returns {Object} Hash of filter values
 */
export const fromSearchToVariables = ({
  runnerType = null,
  membership = null,
  filters = [],
  sort = null,
  pagination = {},
} = {}) => {
  const filterVariables = {};

  const queryObj = filterToQueryObject(processFilters(filters), {
    filteredSearchTermKey: PARAM_KEY_SEARCH,
  });

  [filterVariables.status] = queryObj[PARAM_KEY_STATUS] || [];
  filterVariables.search = queryObj[PARAM_KEY_SEARCH];
  filterVariables.tagList = queryObj[PARAM_KEY_TAG];
  [filterVariables.versionPrefix] = queryObj[PARAM_KEY_VERSION] || [];
  [filterVariables.creator] = queryObj[PARAM_KEY_CREATOR] || [];

  if (queryObj[PARAM_KEY_PAUSED]) {
    filterVariables.paused = parseBoolean(queryObj[PARAM_KEY_PAUSED]);
  } else {
    filterVariables.paused = undefined;
  }

  if (runnerType) {
    filterVariables.type = runnerType;
  }
  if (membership) {
    filterVariables.membership = membership;
  }
  if (sort) {
    filterVariables.sort = sort;
  }

  const paginationVariables = getPaginationVariables(pagination, RUNNER_PAGE_SIZE);

  return {
    ...filterVariables,
    ...paginationVariables,
  };
};

/**
 * Decides whether or not a search object is the "default" or empty.
 *
 * A search is filtered if the user has entered filtering criteria.
 *
 * @param {Object} search
 * @returns true if this search is filtered, false otherwise
 */
export const isSearchFiltered = ({ runnerType = null, filters = [], pagination = {} } = {}) => {
  return Boolean(
    runnerType !== null || filters?.length !== 0 || pagination?.before || pagination?.after,
  );
};
