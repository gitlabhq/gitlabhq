import { queryToObject } from '~/lib/utils/url_utility';
import { TOKENS } from './constants';

export const generateUserPaths = (paths, id) => {
  return Object.fromEntries(
    Object.entries(paths).map(([action, genericPath]) => {
      return [action, genericPath.replace('id', id)];
    }),
  );
};

/**
 * @typedef {{type: string, value: {data: string, operator: string}}} Token
 */

/**
 * Initialize token values based on the URL parameters
 * @param {string} query - document.location.searchd
 *
 * @returns {{tokens: Array<string|Token>, sort: string}}
 */
export function initializeValuesFromQuery(query = document.location.search) {
  const tokens = [];

  const { filter, search_query: searchQuery, sort } = queryToObject(query);

  if (filter) {
    const token = TOKENS.find(({ options }) => options.some(({ value }) => value === filter));

    if (token) {
      tokens.push({
        type: token.type,
        value: {
          data: filter,
          operator: token.operators[0].value,
        },
      });
    }
  }

  if (searchQuery) {
    tokens.push(searchQuery);
  }

  return { tokens, sort };
}
