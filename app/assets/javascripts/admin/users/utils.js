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
 * Initialize values based on the URL parameters
 * @param {string} query
 */
export function initializeValues(query = document.location.search) {
  const values = [];

  const { filter, search_query: searchQuery } = queryToObject(query);

  if (filter) {
    const token = TOKENS.find(({ options }) => options.some(({ value }) => value === filter));

    if (token) {
      values.push({
        type: token.type,
        value: {
          data: filter,
          operator: token.operators[0].value,
        },
      });
    }
  }

  if (searchQuery) {
    values.push(searchQuery);
  }

  return values;
}
