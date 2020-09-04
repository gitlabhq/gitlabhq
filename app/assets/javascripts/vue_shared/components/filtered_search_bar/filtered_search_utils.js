import { isEmpty } from 'lodash';
import { queryToObject } from '~/lib/utils/url_utility';

/**
 * Strips enclosing quotations from a string if it has one.
 *
 * @param {String} value String to strip quotes from
 *
 * @returns {String} String without any enclosure
 */
export const stripQuotes = value => value.replace(/^('|")(.*)('|")$/, '$2');

/**
 * This method removes duplicate tokens from tokens array.
 *
 * @param {Array} tokens Array of tokens as defined by `GlFilteredSearch`
 *
 * @returns {Array} Unique array of tokens
 */
export const uniqueTokens = tokens => {
  const knownTokens = [];
  return tokens.reduce((uniques, token) => {
    if (typeof token === 'object' && token.type !== 'filtered-search-term') {
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
      return [...memo, ...value.map(filterValue => createToken(key, filterValue))];
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

/**
 * This function takes a filter object and maps it into a query object. Example filter:
 * { myFilterName: { value: 'foo', operator: '=' } }
 * gets translated into:
 * { myFilterName: 'foo', 'not[myFilterName]': null }
 * @param  {Object} filters
 * @param  {Object.myFilterName} a single filter value or an array of filters
 * @return {Object} query object with both filter name and not-name with values
 */
export function filterToQueryObject(filters = {}) {
  return Object.keys(filters).reduce((memo, key) => {
    const filter = filters[key];

    let selected;
    let unselected;
    if (Array.isArray(filter)) {
      selected = filter.filter(item => item.operator === '=').map(item => item.value);
      unselected = filter.filter(item => item.operator === '!=').map(item => item.value);
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
 * @return {Object.filterName} extracted filtern ame
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
 * This function takes a URL query string and maps it into a filter object. Example query string:
 * '?myFilterName=foo'
 * gets translated into:
 * { myFilterName: { value: 'foo', operator: '=' } }
 * @param  {String} query URL quert string, e.g. from `window.location.search`
 * @return {Object} filter object with filter names and their values
 */
export function urlQueryToFilter(query = '') {
  const filters = queryToObject(query, { gatherArrays: true });
  return Object.keys(filters).reduce((memo, key) => {
    const value = filters[key];
    if (!value) {
      return memo;
    }
    const { filterName, operator } = extractNameAndOperator(key);
    let previousValues = [];
    if (Array.isArray(memo[filterName])) {
      previousValues = memo[filterName];
    }
    if (Array.isArray(value)) {
      const newAdditions = value.filter(Boolean).map(item => ({ value: item, operator }));
      return { ...memo, [filterName]: [...previousValues, ...newAdditions] };
    }

    return { ...memo, [filterName]: { value, operator } };
  }, {});
}
