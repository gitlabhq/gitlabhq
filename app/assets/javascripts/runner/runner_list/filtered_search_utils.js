import { queryToObject, setUrlParams } from '~/lib/utils/url_utility';
import {
  PARAM_KEY_STATUS,
  PARAM_KEY_RUNNER_TYPE,
  PARAM_KEY_SORT,
  DEFAULT_SORT,
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

export const fromUrlQueryToSearch = (query = window.location.search) => {
  const params = queryToObject(query, { gatherArrays: true });

  return {
    filters: [
      ...getFilterFromParams(PARAM_KEY_STATUS, params),
      ...getFilterFromParams(PARAM_KEY_RUNNER_TYPE, params),
    ],
    sort: params[PARAM_KEY_SORT] || DEFAULT_SORT,
  };
};

export const fromSearchToUrl = ({ filters = [], sort = null }, url = window.location.href) => {
  const urlParams = {
    [PARAM_KEY_STATUS]: getValuesFromFilters(PARAM_KEY_STATUS, filters),
    [PARAM_KEY_RUNNER_TYPE]: getValuesFromFilters(PARAM_KEY_RUNNER_TYPE, filters),
  };

  if (sort && sort !== DEFAULT_SORT) {
    urlParams[PARAM_KEY_SORT] = sort;
  }

  return setUrlParams(urlParams, url, false, true, true);
};

export const fromSearchToVariables = ({ filters = [], sort = null } = {}) => {
  const variables = {};

  // TODO Get more than one value when GraphQL API supports OR for "status"
  [variables.status] = getValuesFromFilters(PARAM_KEY_STATUS, filters);

  // TODO Get more than one value when GraphQL API supports OR for "runner type"
  [variables.type] = getValuesFromFilters(PARAM_KEY_RUNNER_TYPE, filters);

  if (sort) {
    variables.sort = sort;
  }

  return variables;
};
