import { queryToObject, setUrlParams } from '~/lib/utils/url_utility';
import {
  PARAM_KEY_STATUS,
  PARAM_KEY_RUNNER_TYPE,
  PARAM_KEY_SORT,
  PARAM_KEY_PAGE,
  PARAM_KEY_AFTER,
  PARAM_KEY_BEFORE,
  DEFAULT_SORT,
  RUNNER_PAGE_SIZE,
} from '../constants';

const getValuesFromFilters = (paramKey, filters) => {
  return filters
    .filter(({ type, value }) => type === paramKey && value.operator === '=')
    .map(({ value }) => value.data);
};

const getFilterFromParams = (paramKey, params) => {
  const value = params[paramKey];
  if (!value) {
    return [];
  }

  const values = Array.isArray(value) ? value : [value];
  return values.map((data) => {
    return {
      type: paramKey,
      value: {
        data,
        operator: '=',
      },
    };
  });
};

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
    filters: [
      ...getFilterFromParams(PARAM_KEY_STATUS, params),
      ...getFilterFromParams(PARAM_KEY_RUNNER_TYPE, params),
    ],
    sort: params[PARAM_KEY_SORT] || DEFAULT_SORT,
    pagination: getPaginationFromParams(params),
  };
};

export const fromSearchToUrl = (
  { filters = [], sort = null, pagination = {} },
  url = window.location.href,
) => {
  const urlParams = {
    [PARAM_KEY_STATUS]: getValuesFromFilters(PARAM_KEY_STATUS, filters),
    [PARAM_KEY_RUNNER_TYPE]: getValuesFromFilters(PARAM_KEY_RUNNER_TYPE, filters),
  };

  if (sort && sort !== DEFAULT_SORT) {
    urlParams[PARAM_KEY_SORT] = sort;
  }

  // Remove pagination params for first page
  if (pagination?.page === 1) {
    urlParams[PARAM_KEY_PAGE] = null;
    urlParams[PARAM_KEY_BEFORE] = null;
    urlParams[PARAM_KEY_AFTER] = null;
  } else {
    urlParams[PARAM_KEY_PAGE] = pagination.page;
    urlParams[PARAM_KEY_BEFORE] = pagination.before;
    urlParams[PARAM_KEY_AFTER] = pagination.after;
  }

  return setUrlParams(urlParams, url, false, true, true);
};

export const fromSearchToVariables = ({ filters = [], sort = null, pagination = {} } = {}) => {
  const variables = {};

  // TODO Get more than one value when GraphQL API supports OR for "status"
  [variables.status] = getValuesFromFilters(PARAM_KEY_STATUS, filters);

  // TODO Get more than one value when GraphQL API supports OR for "runner type"
  [variables.type] = getValuesFromFilters(PARAM_KEY_RUNNER_TYPE, filters);

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
