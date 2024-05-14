import { queryToObject } from '~/lib/utils/url_utility';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';

export const getQueryParams = (query) =>
  queryToObject(query, { gatherArrays: true, legacySpacesDecode: true });

export const keyValueToFilterToken = (type, data) => ({ type, value: { data } });

export const searchArrayToFilterTokens = (search) =>
  search.map((s) => keyValueToFilterToken(FILTERED_SEARCH_TERM, s));

export const extractFilterAndSorting = (queryObject) => {
  const { type, search, version, status, sort, orderBy } = queryObject;
  const filters = [];
  const sorting = {};

  if (type) {
    filters.push(keyValueToFilterToken('type', type));
  }
  if (version) {
    filters.push(keyValueToFilterToken('version', version));
  }
  if (status) {
    filters.push(keyValueToFilterToken('status', status));
  }
  if (search) {
    filters.push(...searchArrayToFilterTokens(search));
  }
  if (sort) {
    sorting.sort = sort;
  }
  if (orderBy) {
    sorting.orderBy = orderBy;
  }
  return { filters, sorting };
};

export const extractPageInfo = (queryObject) => {
  const { before, after } = queryObject;
  return {
    before,
    after,
  };
};

export const beautifyPath = (path) => (path ? path.split('/').join(' / ') : '');

export const getCommitLink = ({ project_path: projectPath, pipeline = {} }, isGroup = false) => {
  if (isGroup) {
    return `/${projectPath}/commit/${pipeline.sha}`;
  }

  return `../commit/${pipeline.sha}`;
};
