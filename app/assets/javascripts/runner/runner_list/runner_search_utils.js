import { queryToObject, setUrlParams } from '~/lib/utils/url_utility';
import {
  filterToQueryObject,
  processFilters,
  urlQueryToFilter,
  prepareTokens,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import {
  PARAM_KEY_STATUS,
  PARAM_KEY_RUNNER_TYPE,
  PARAM_KEY_TAG,
  PARAM_KEY_SEARCH,
  PARAM_KEY_SORT,
  PARAM_KEY_PAGE,
  PARAM_KEY_AFTER,
  PARAM_KEY_BEFORE,
  DEFAULT_SORT,
  RUNNER_PAGE_SIZE,
} from '../constants';

const getPaginationFromParams = (params) => {
  const page = parseInt(params[PARAM_KEY_PAGE], 10);
  const after = params[PARAM_KEY_AFTER];
  const before = params[PARAM_KEY_BEFORE];

  if (page && (before || after)) {
    return {
      page,
      before,
      after,
    };
  }
  return {
    page: 1,
  };
};

export const fromUrlQueryToSearch = (query = window.location.search) => {
  const params = queryToObject(query, { gatherArrays: true });

  return {
    filters: prepareTokens(
      urlQueryToFilter(query, {
        filterNamesAllowList: [PARAM_KEY_STATUS, PARAM_KEY_RUNNER_TYPE, PARAM_KEY_TAG],
        filteredSearchTermKey: PARAM_KEY_SEARCH,
        legacySpacesDecode: false,
      }),
    ),
    sort: params[PARAM_KEY_SORT] || DEFAULT_SORT,
    pagination: getPaginationFromParams(params),
  };
};

export const fromSearchToUrl = (
  { filters = [], sort = null, pagination = {} },
  url = window.location.href,
) => {
  const filterParams = {
    // Defaults
    [PARAM_KEY_STATUS]: [],
    [PARAM_KEY_RUNNER_TYPE]: [],
    [PARAM_KEY_TAG]: [],
    // Current filters
    ...filterToQueryObject(processFilters(filters), {
      filteredSearchTermKey: PARAM_KEY_SEARCH,
    }),
  };

  if (!filterParams[PARAM_KEY_SEARCH]) {
    filterParams[PARAM_KEY_SEARCH] = null;
  }

  const isDefaultSort = sort !== DEFAULT_SORT;
  const isFirstPage = pagination?.page === 1;
  const otherParams = {
    // Sorting & Pagination
    [PARAM_KEY_SORT]: isDefaultSort ? sort : null,
    [PARAM_KEY_PAGE]: isFirstPage ? null : pagination.page,
    [PARAM_KEY_BEFORE]: isFirstPage ? null : pagination.before,
    [PARAM_KEY_AFTER]: isFirstPage ? null : pagination.after,
  };

  return setUrlParams({ ...filterParams, ...otherParams }, url, false, true, true);
};

export const fromSearchToVariables = ({ filters = [], sort = null, pagination = {} } = {}) => {
  const variables = {};

  const queryObj = filterToQueryObject(processFilters(filters), {
    filteredSearchTermKey: PARAM_KEY_SEARCH,
  });

  variables.search = queryObj[PARAM_KEY_SEARCH];

  // TODO Get more than one value when GraphQL API supports OR for "status" or "runner_type"
  [variables.status] = queryObj[PARAM_KEY_STATUS] || [];
  [variables.type] = queryObj[PARAM_KEY_RUNNER_TYPE] || [];

  variables.tagList = queryObj[PARAM_KEY_TAG];

  if (sort) {
    variables.sort = sort;
  }

  if (pagination.before) {
    variables.before = pagination.before;
    variables.last = RUNNER_PAGE_SIZE;
  } else {
    variables.after = pagination.after;
    variables.first = RUNNER_PAGE_SIZE;
  }

  return variables;
};
