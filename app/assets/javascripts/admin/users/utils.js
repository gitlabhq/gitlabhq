import { queryToObject } from '~/lib/utils/url_utility';
import getSoloOwnedOrganizationsQuery from '~/admin/users/graphql/queries/get_solo_owned_organizations.query.graphql';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import {
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

const createTokenValue = (type, value) => ({
  type,
  value: { data: value, operator: OPERATOR_IS },
});

/**
 * @typedef {{type: string, value: {data: string, operator: string}}} Token
 */

/**
 * Initialize token values based on the URL parameters
 *
 * @returns {{tokenValues: Array<string|Token>, sort: string}}
 */
export function initializeValuesFromQuery(filterTokenConfigs, standardTokenConfigs) {
  const tokenValues = [];
  const {
    filter,
    search_query: searchQuery,
    sort,
    ...otherProperties
  } = queryToObject(window.location.search);

  // If there's a filter querystring, check if it's for a filter token config, and if so, add it.
  if (filter) {
    // Get the token config that has an option with the same value as the querystring value.
    const tokenConfig = filterTokenConfigs.find(({ options }) =>
      options.some(({ value }) => value === filter),
    );

    if (tokenConfig) {
      tokenValues.push(createTokenValue(tokenConfig.type, filter));
    }
  }
  // If there's a text search, add it as a token.
  if (searchQuery) {
    tokenValues.push(searchQuery);
  }
  // For all other properties, check if it's for a standard token config, and if so, add it.
  Object.entries(otherProperties).forEach(([type, value]) => {
    if (standardTokenConfigs.some((token) => token.type === type)) {
      tokenValues.push(createTokenValue(type, value));
    }
  });

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
