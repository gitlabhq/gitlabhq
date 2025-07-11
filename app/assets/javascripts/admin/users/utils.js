import { queryToObject } from '~/lib/utils/url_utility';
import getSoloOwnedOrganizationsQuery from '~/admin/users/graphql/queries/get_solo_owned_organizations.query.graphql';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import {
  TOKEN_CONFIGS,
  SOLO_OWNED_ORGANIZATIONS_EMPTY,
  SOLO_OWNED_ORGANIZATIONS_REQUESTED_COUNT,
} from 'ee_else_ce/admin/users/constants';
import { OPERATOR_IS } from '~/vue_shared/components/filtered_search_bar/constants';

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
 *
 * @returns {{tokenValues: Array<string|Token>, sort: string}}
 */
export function initializeValuesFromQuery() {
  const tokenValues = [];

  const { filter, search_query: searchQuery, sort } = queryToObject(window.location.search);

  if (filter) {
    const tokenConfig = TOKEN_CONFIGS.find(({ options }) =>
      options.some(({ value }) => value === filter),
    );

    if (tokenConfig) {
      tokenValues.push({
        type: tokenConfig.type,
        value: { data: filter, operator: OPERATOR_IS },
      });
    }
  }

  if (searchQuery) {
    tokenValues.push(searchQuery);
  }

  return { tokenValues, sort };
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
