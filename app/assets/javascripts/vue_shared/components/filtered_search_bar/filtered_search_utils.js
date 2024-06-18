import { isEmpty, uniqWith, isEqual, isString } from 'lodash';
import AccessorUtilities from '~/lib/utils/accessor';
import { queryToObject } from '~/lib/utils/url_utility';

import { MAX_RECENT_TOKENS_SIZE, FILTERED_SEARCH_TERM } from './constants';

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

/**
 * This function takes a token array and translates it into a filter object
 * @param filters
 * @returns A Filter Object
 */
export function processFilters(filters) {
  return filters.reduce((acc, token) => {
    let type;
    let value;
    let operator;
    if (typeof token === 'string') {
      type = FILTERED_SEARCH_TERM;
      value = token;
    } else {
      type = token?.type;
      operator = token?.value?.operator;
      value = token?.value?.data;
    }

    if (!acc[type]) {
      acc[type] = [];
    }

    acc[type].push({ value, operator });
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
 * By default it supports '=' and '!=' operators. This can be extended by providing the `customOperators` option
 * @param  {Object} filters
 * @param  {Object} filters.myFilterName a single filter value or an array of filters
 * @param  {Object} options
 * @param  {Object} [options.filteredSearchTermKey] if set, 'filtered-search-term' filters are assigned to this key, 'search' is suggested
 * @param  {Object} [options.customOperators] Allows to extend the supported operators, e.g.
 *
 *    filterToQueryObject({foo: [{ value: '100', operator: '>' }]}, {customOperators: {operator: '>',prefix: 'gt'}})
 *      returns {gt[foo]: '100'}
 *    It's also possible to restrict custom operators to a given key by setting `applyOnlyToKey` string attribute.
 *
 * @return {Object} query object with both filter name and not-name with values
 */
export function filterToQueryObject(filters = {}, options = {}) {
  const { filteredSearchTermKey, customOperators, shouldExcludeEmpty = false } = options;

  return Object.keys(filters).reduce((memo, key) => {
    const filter = filters[key];

    if (typeof filteredSearchTermKey === 'string' && key === FILTERED_SEARCH_TERM && filter) {
      const combinedFilteredSearchTerm = filteredSearchQueryParam(filter);
      if (combinedFilteredSearchTerm === '' && shouldExcludeEmpty) {
        return memo;
      }

      return { ...memo, [filteredSearchTermKey]: filteredSearchQueryParam(filter) };
    }

    const operators = [
      { operator: '=' },
      { operator: '!=', prefix: 'not' },
      ...(customOperators ?? []),
    ];

    const result = {};

    for (const op of operators) {
      const { operator, prefix, applyOnlyToKey } = op;

      if (!applyOnlyToKey || applyOnlyToKey === key) {
        let value;
        if (Array.isArray(filter)) {
          value = filter.filter((item) => item.operator === operator).map((item) => item.value);
        } else {
          value = filter?.operator === operator ? filter.value : null;
        }

        if (isEmpty(value)) {
          value = null;
        }

        if (shouldExcludeEmpty && (value?.[0] === '' || value === '' || value === null)) {
          // eslint-disable-next-line no-continue
          continue;
        }

        if (prefix) {
          result[`${prefix}[${key}]`] = value;
        } else {
          result[key] = value;
        }
      }
    }

    return { ...memo, ...result };
  }, {});
}

/**
 * Extracts filter name from url name and operator, e.g.
 *  e.g. input: not[my_filter]` output: {filterName: `my_filter`, operator: '!='}`
 *
 * By default it supports filter with the format `my_filter=foo` and `not[my_filter]=bar`. This can be extended with the `customOperators` option.
 * @param  {String} filterName from url
 * @param {Object.customOperators} It allows to extend the supported parameter, e.g.
 *  input: 'gt[filter]', { customOperators: [{ operator: '>', prefix: 'gt' }]})
 *  output: '{filterName: 'filter', operator: '>'}
 * @return {Object}
 * @return {Object.filterName} extracted filter name
 * @return {Object.operator} `=` or `!=`
 */
function extractNameAndOperator(filterName, customOperators) {
  const ops = [
    {
      prefix: 'not',
      operator: '!=',
    },
    ...(customOperators ?? []),
  ];

  const operator = ops.find(
    ({ prefix }) => filterName.startsWith(`${prefix}[`) && filterName.endsWith(']'),
  );

  if (!operator) {
    return { filterName, operator: '=' };
  }
  const { prefix } = operator;
  return { filterName: filterName.slice(prefix.length + 1, -1), operator: operator.operator };
}

/**
 * Gathers search term as values
 * @param {String|Array} value
 * @returns {Array} List of search terms split by word
 */
function filteredSearchTermValue(value) {
  const values = Array.isArray(value) ? value : [value];
  return [{ value: values.filter((term) => term).join(' ') }];
}

/**
 * This function takes a URL query string and maps it into a filter object. Example query string:
 * '?myFilterName=foo'
 * gets translated into:
 * { myFilterName: { value: 'foo', operator: '=' } }
 * By default it only support '=' and '!=' operators. This can be extended with the customOperator option.
 * @param  {String|Object} query URL query string or object, e.g. from `window.location.search` or `this.$route.query`
 * @param  {Object} options
 * @param  {String} [options.filteredSearchTermKey] if set, a FILTERED_SEARCH_TERM filter is created to this parameter. `'search'` is suggested
 * @param  {String[]} [options.filterNamesAllowList] if set, only this list of filters names is mapped
 * @param  {Object} [options.customOperator] It allows to extend the supported parameter, e.g.
 *  input: 'gt[myFilter]=100', { customOperators: [{ operator: '>', prefix: 'gt' }]})
 *  output: '{ myFilter: {value: '100', operator: '>'}}
 * @return {Object} filter object with filter names and their values
 */
export function urlQueryToFilter(
  query = '',
  { filteredSearchTermKey, filterNamesAllowList, customOperators } = {},
) {
  const filters = isString(query) ? queryToObject(query, { gatherArrays: true }) : query;
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

    const { filterName, operator } = extractNameAndOperator(key, customOperators);
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
 * @param {Array} appliedTokens
 * @param {Function} valueIdentifier
 * @returns
 */
export function getRecentlyUsedSuggestions(
  recentSuggestionsStorageKey,
  appliedTokens,
  valueIdentifier,
) {
  let recentlyUsedSuggestions = [];
  if (AccessorUtilities.canUseLocalStorage()) {
    recentlyUsedSuggestions = JSON.parse(localStorage.getItem(recentSuggestionsStorageKey)) || [];
  }
  return recentlyUsedSuggestions.filter((suggestion) => {
    return !appliedTokens?.some(
      (appliedToken) => appliedToken.value.data === valueIdentifier(suggestion),
    );
  });
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

  if (AccessorUtilities.canUseLocalStorage()) {
    localStorage.setItem(
      recentSuggestionsStorageKey,
      JSON.stringify(uniqWith(recentlyUsedSuggestions, isEqual).slice(0, MAX_RECENT_TOKENS_SIZE)),
    );
  }
}

/**
 * Removes `FILTERED_SEARCH_TERM` tokens with empty data
 *
 * @param filterTokens array of filtered search tokens
 * @return {Array} array of filtered search tokens
 */
export const filterEmptySearchTerm = (filterTokens = []) =>
  filterTokens.filter((token) => token.type === FILTERED_SEARCH_TERM && token.value.data);
