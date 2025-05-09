import { queryToObject } from '~/lib/utils/url_utility';
import getSoloOwnedOrganizationsQuery from '~/admin/users/graphql/queries/get_solo_owned_organizations.query.graphql';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import {
  TOKENS,
  SOLO_OWNED_ORGANIZATIONS_EMPTY,
  SOLO_OWNED_ORGANIZATIONS_REQUESTED_COUNT,
} from './constants';

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

export const getSoloOwnedOrganizations = async (apolloClient, userId) => {
  if (!window.gon?.features?.uiForOrganizations) {
    return Promise.resolve(SOLO_OWNED_ORGANIZATIONS_EMPTY);
  }

  const {
    data: {
      user: { organizations },
    },
  } = await apolloClient.query({
    query: getSoloOwnedOrganizationsQuery,
    variables: {
      id: convertToGraphQLId(TYPENAME_USER, userId),
      first: SOLO_OWNED_ORGANIZATIONS_REQUESTED_COUNT,
    },
  });

  return organizations;
};
