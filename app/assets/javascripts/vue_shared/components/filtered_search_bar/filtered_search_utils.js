import { isEmpty, uniqWith, isEqual } from 'lodash';
import AccessorUtilities from '~/lib/utils/accessor';
import { queryToObject } from '~/lib/utils/url_utility';

import { MAX_RECENT_TOKENS_SIZE, FILTERED_SEARCH_TERM } from './constants';

/**
 * Strips enclosing quotations from a string if it has one.
 *
 * @param {String} value String to strip quotes from
 *
 * @returns {String} String without any enclosure
 */
export const stripQuotes = (value) => value.replace(/^('|")(.*)('|")$/, '$2');

/**
 * This method removes duplicate tokens from tokens array.
 *
 * @param {Array} tokens Array of tokens as defined by `GlFilteredSearch`
 *
 * @returns {Array} Unique array of tokens
 */
export const uniqueTokens = (tokens) => {
  const knownTokens = [];
  return tokens.reduce((uniques, token) => {
    if (typeof token === 'object' && token.type !== FILTERED_SEARCH_TERM) {
      const tokenString = `${token.type}${token.value.operator}${token.value.data}`;
      if (!knownTokens.includes(tokenString)) {
        uniques.push(token);
        knownTokens.push(tokenString);
      }
    } else {
      uniques.push(token);
    }
    return uniques;
  }, []);
};

/**
 * Creates a token from a type and a filter. Example returned object
 * { type: 'myType', value: { data: 'myData', operator: '= '} }
 * @param  {String} type the name of the filter
 * @param  {Object}
 * @param  {Object.value} filter value to be returned as token data
 * @param  {Object.operator} filter operator to be retuned as token operator
 * @return {Object}
 * @return {Object.type} token type
 * @return {Object.value} token value
 */
function createToken(type, filter) {
  return { type, value: { data: filter.value, operator: filter.operator } };
}

/**
 * This function takes a filter object and translates it into a token array
 * @param  {Object} filters
 * @param  {Object.myFilterName} a single filter value or an array of filters
 * @return {Array} tokens an array of tokens created from filter values
 */
export function prepareTokens(filters = {}) {
  return Object.keys(filters).reduce((memo, key) => {
    const value = filters[key];
    if (!value) {
      return memo;
    }
    if (Array.isArray(value)) {
      return [...memo, ...value.map((filterValue) => createToken(key, filterValue))];
    }

    return [...memo, createToken(key, value)];
  }, []);
}

export function processFilters(filters) {
  return filters.reduce((acc, token) => {
    const { type, value } = token;
    const { operator } = value;
    const tokenValue = value.data;

    if (!acc[type]) {
      acc[type] = [];
    }

    acc[type].push({ value: tokenValue, operator });
    return acc;
  }, {});
}

function filteredSearchQueryParam(filter) {
  return filter
    .map(({ value }) => value)
    .join(' ')
    .trim();
}

/**
 * This function takes a filter object and maps it into a query object. Example filter:
 * { myFilterName: { value: 'foo', operator: '=' }, search: [{ value: 'my' }, { value: 'search' }] }
 * gets translated into:
 * { myFilterName: 'foo', 'not[myFilterName]': null, search: 'my search' }
 * @param  {Object} filters
 * @param  {Object} filters.myFilterName a single filter value or an array of filters
 * @param  {Object} options
 * @param  {Object} [options.filteredSearchTermKey] if set, 'filtered-search-term' filters are assigned to this key, 'search' is suggested
 * @return {Object} query object with both filter name and not-name with values
 */
export function filterToQueryObject(filters = {}, options = {}) {
  const { filteredSearchTermKey } = options;

  return Object.keys(filters).reduce((memo, key) => {
    const filter = filters[key];

    if (typeof filteredSearchTermKey === 'string' && key === FILTERED_SEARCH_TERM) {
      return { ...memo, [filteredSearchTermKey]: filteredSearchQueryParam(filter) };
    }

    let selected;
    let unselected;

    if (Array.isArray(filter)) {
      selected = filter.filter((item) => item.operator === '=').map((item) => item.value);
      unselected = filter.filter((item) => item.operator === '!=').map((item) => item.value);
    } else {
      selected = filter?.operator === '=' ? filter.value : null;
      unselected = filter?.operator === '!=' ? filter.value : null;
    }

    if (isEmpty(selected)) {
      selected = null;
    }
    if (isEmpty(unselected)) {
      unselected = null;
    }

    return { ...memo, [key]: selected, [`not[${key}]`]: unselected };
  }, {});
}

/**
 * Extracts filter name from url name, e.g. `not[my_filter]` => `my_filter`
 * and returns the operator with it depending on the filter name
 * @param  {String} filterName from url
 * @return {Object}
 * @return {Object.filterName} extracted filter name
 * @return {Object.operator} `=` or `!=`
 */
function extractNameAndOperator(filterName) {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  if (filterName.startsWith('not[') && filterName.endsWith(']')) {
    return { filterName: filterName.slice(4, -1), operator: '!=' };
  }

  return { filterName, operator: '=' };
}

/**
 * Gathers search term as values
 * @param {String|Array} value
 * @returns {Array} List of search terms split by word
 */
function filteredSearchTermValue(value) {
  const values = Array.isArray(value) ? value : [value];
  return values
    .filter((term) => term)
    .join(' ')
    .split(' ')
    .map((term) => ({ value: term }));
}

/**
 * This function takes a URL query string and maps it into a filter object. Example query string:
 * '?myFilterName=foo'
 * gets translated into:
 * { myFilterName: { value: 'foo', operator: '=' } }
 * @param  {String} query URL query string, e.g. from `window.location.search`
 * @param  {Object} options
 * @param  {Object} options
 * @param  {String} [options.filteredSearchTermKey] if set, a FILTERED_SEARCH_TERM filter is created to this parameter. `'search'` is suggested
 * @param  {String[]} [options.filterNamesAllowList] if set, only this list of filters names is mapped
 * @param  {Boolean} [options.legacySpacesDecode] if set, plus symbols (+) are not encoded as spaces. `false` is suggested
 * @return {Object} filter object with filter names and their values
 */
export function urlQueryToFilter(query = '', options = {}) {
  const { filteredSearchTermKey, filterNamesAllowList, legacySpacesDecode = true } = options;

  const filters = queryToObject(query, { gatherArrays: true, legacySpacesDecode });
  return Object.keys(filters).reduce((memo, key) => {
    const value = filters[key];
    if (!value) {
      return memo;
    }
    if (key === filteredSearchTermKey) {
      return {
        ...memo,
        [FILTERED_SEARCH_TERM]: filteredSearchTermValue(value),
      };
    }

    const { filterName, operator } = extractNameAndOperator(key);
    if (filterNamesAllowList && !filterNamesAllowList.includes(filterName)) {
      return memo;
    }
    let previousValues = [];
    if (Array.isArray(memo[filterName])) {
      previousValues = memo[filterName];
    }
    if (Array.isArray(value)) {
      const newAdditions = value.filter(Boolean).map((item) => ({ value: item, operator }));
      return { ...memo, [filterName]: [...previousValues, ...newAdditions] };
    }

    return { ...memo, [filterName]: { value, operator } };
  }, {});
}

/**
 * Returns array of token values from localStorage
 * based on provided recentSuggestionsStorageKey
 *
 * @param {String} recentSuggestionsStorageKey
 * @returns
 */
export function getRecentlyUsedSuggestions(recentSuggestionsStorageKey) {
  let recentlyUsedSuggestions = [];
  if (AccessorUtilities.isLocalStorageAccessSafe()) {
    recentlyUsedSuggestions = JSON.parse(localStorage.getItem(recentSuggestionsStorageKey)) || [];
  }
  return recentlyUsedSuggestions;
}

/**
 * Sets provided token value to recently used array
 * within localStorage for provided recentSuggestionsStorageKey
 *
 * @param {String} recentSuggestionsStorageKey
 * @param {Object} tokenValue
 */
export function setTokenValueToRecentlyUsed(recentSuggestionsStorageKey, tokenValue) {
  const recentlyUsedSuggestions = getRecentlyUsedSuggestions(recentSuggestionsStorageKey);

  recentlyUsedSuggestions.splice(0, 0, { ...tokenValue });

  if (AccessorUtilities.isLocalStorageAccessSafe()) {
    localStorage.setItem(
      recentSuggestionsStorageKey,
      JSON.stringify(uniqWith(recentlyUsedSuggestions, isEqual).slice(0, MAX_RECENT_TOKENS_SIZE)),
    );
  }
}
