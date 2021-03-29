import { queryToObject } from '~/lib/utils/url_utility';
import { FILTERED_SEARCH_TERM } from './constants';

export const getQueryParams = (query) => queryToObject(query, { gatherArrays: true });

export const keyValueToFilterToken = (type, data) => ({ type, value: { data } });

export const searchArrayToFilterTokens = (search) =>
  search.map((s) => keyValueToFilterToken(FILTERED_SEARCH_TERM, s));
