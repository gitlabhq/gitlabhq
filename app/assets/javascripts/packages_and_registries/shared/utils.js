import { queryToObject } from '~/lib/utils/url_utility';
import { FILTERED_SEARCH_TERM } from './constants';

export const getQueryParams = (query) =>
  queryToObject(query, { gatherArrays: true, legacySpacesDecode: true });

export const keyValueToFilterToken = (type, data) => ({ type, value: { data } });

export const searchArrayToFilterTokens = (search) =>
  search.map((s) => keyValueToFilterToken(FILTERED_SEARCH_TERM, s));

export const extractFilterAndSorting = (queryObject) => {
  const { type, search, sort, orderBy } = queryObject;
  const filters = [];
  const sorting = {};

  if (type) {
    filters.push(keyValueToFilterToken('type', type));
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
