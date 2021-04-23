import { FILTERED_SEARCH_TERM, filters, sortParams } from '~/issues_list/constants';

export const getSortKey = (orderBy, sort) =>
  Object.keys(sortParams).find(
    (key) => sortParams[key].order_by === orderBy && sortParams[key].sort === sort,
  );

const tokenTypes = Object.keys(filters);

const urlParamKeys = tokenTypes.flatMap((key) => Object.values(filters[key].urlParam));

const getTokenTypeFromUrlParamKey = (urlParamKey) =>
  tokenTypes.find((key) => Object.values(filters[key].urlParam).includes(urlParamKey));

const getOperatorFromUrlParamKey = (tokenType, urlParamKey) =>
  Object.entries(filters[tokenType].urlParam).find(([, urlParam]) => urlParam === urlParamKey)[0];

const convertToFilteredTokens = (locationSearch) =>
  Array.from(new URLSearchParams(locationSearch).entries())
    .filter(([key]) => urlParamKeys.includes(key))
    .map(([key, data]) => {
      const type = getTokenTypeFromUrlParamKey(key);
      const operator = getOperatorFromUrlParamKey(type, key);
      return {
        type,
        value: { data, operator },
      };
    });

const convertToFilteredSearchTerms = (locationSearch) =>
  new URLSearchParams(locationSearch)
    .get('search')
    ?.split(' ')
    .map((word) => ({
      type: FILTERED_SEARCH_TERM,
      value: {
        data: word,
      },
    })) || [];

export const getFilterTokens = (locationSearch) => {
  if (!locationSearch) {
    return [];
  }
  const filterTokens = convertToFilteredTokens(locationSearch);
  const searchTokens = convertToFilteredSearchTerms(locationSearch);
  return filterTokens.concat(searchTokens);
};

export const convertToApiParams = (filterTokens) =>
  filterTokens
    .filter((token) => token.type !== FILTERED_SEARCH_TERM)
    .reduce((acc, token) => {
      const apiParam = filters[token.type].apiParam[token.value.operator];
      return Object.assign(acc, {
        [apiParam]: acc[apiParam] ? `${acc[apiParam]},${token.value.data}` : token.value.data,
      });
    }, {});

export const convertToUrlParams = (filterTokens) =>
  filterTokens
    .filter((token) => token.type !== FILTERED_SEARCH_TERM)
    .reduce((acc, token) => {
      const urlParam = filters[token.type].urlParam[token.value.operator];
      return Object.assign(acc, {
        [urlParam]: acc[urlParam] ? acc[urlParam].concat(token.value.data) : [token.value.data],
      });
    }, {});

export const convertToSearchQuery = (filterTokens) =>
  filterTokens
    .filter((token) => token.type === FILTERED_SEARCH_TERM && token.value.data)
    .map((token) => token.value.data)
    .join(' ');
