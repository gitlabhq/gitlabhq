import * as types from './mutation_types';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { __ } from '~/locale';
import api from '~/api';
import {
  normalizeHeaders,
  parseIntPagination,
  convertObjectPropsToCamelCase,
} from '~/lib/utils/common_utils';
import allReleasesQuery from '~/releases/queries/all_releases.query.graphql';
import { gqClient, convertAllReleasesGraphQLResponse } from '../../../util';
import { PAGE_SIZE } from '../../../constants';

/**
 * Gets a paginated list of releases from the server
 *
 * @param {Object} vuexParams
 * @param {Object} actionParams
 * @param {Number} [actionParams.page] The page number of results to fetch
 * (this parameter is only used when fetching results from the REST API)
 * @param {String} [actionParams.before] A GraphQL cursor. If provided,
 * the items returned will proceed the provided cursor (this parameter is only
 * used when fetching results from the GraphQL API).
 * @param {String} [actionParams.after] A GraphQL cursor. If provided,
 * the items returned will follow the provided cursor (this parameter is only
 * used when fetching results from the GraphQL API).
 */
export const fetchReleases = ({ dispatch, rootGetters }, { page = 1, before, after }) => {
  if (rootGetters.useGraphQLEndpoint) {
    dispatch('fetchReleasesGraphQl', { before, after });
  } else {
    dispatch('fetchReleasesRest', { page });
  }
};

/**
 * Gets a paginated list of releases from the GraphQL endpoint
 */
export const fetchReleasesGraphQl = (
  { dispatch, commit, state },
  { before = null, after = null },
) => {
  commit(types.REQUEST_RELEASES);

  const { sort, orderBy } = state.sorting;
  const orderByParam = orderBy === 'created_at' ? 'created' : orderBy;
  const sortParams = `${orderByParam}_${sort}`.toUpperCase();

  let paginationParams;
  if (!before && !after) {
    paginationParams = { first: PAGE_SIZE };
  } else if (before && !after) {
    paginationParams = { last: PAGE_SIZE, before };
  } else if (!before && after) {
    paginationParams = { first: PAGE_SIZE, after };
  } else {
    throw new Error(
      'Both a `before` and an `after` parameter were provided to fetchReleasesGraphQl. These parameters cannot be used together.',
    );
  }

  gqClient
    .query({
      query: allReleasesQuery,
      variables: {
        fullPath: state.projectPath,
        sort: sortParams,
        ...paginationParams,
      },
    })
    .then(response => {
      const { data, paginationInfo: graphQlPageInfo } = convertAllReleasesGraphQLResponse(response);

      commit(types.RECEIVE_RELEASES_SUCCESS, {
        data,
        graphQlPageInfo,
      });
    })
    .catch(() => dispatch('receiveReleasesError'));
};

/**
 * Gets a paginated list of releases from the REST endpoint
 */
export const fetchReleasesRest = ({ dispatch, commit, state }, { page }) => {
  commit(types.REQUEST_RELEASES);

  const { sort, orderBy } = state.sorting;

  api
    .releases(state.projectId, { page, sort, order_by: orderBy })
    .then(({ data, headers }) => {
      const restPageInfo = parseIntPagination(normalizeHeaders(headers));
      const camelCasedReleases = convertObjectPropsToCamelCase(data, { deep: true });

      commit(types.RECEIVE_RELEASES_SUCCESS, {
        data: camelCasedReleases,
        restPageInfo,
      });
    })
    .catch(() => dispatch('receiveReleasesError'));
};

export const receiveReleasesError = ({ commit }) => {
  commit(types.RECEIVE_RELEASES_ERROR);
  createFlash(__('An error occurred while fetching the releases. Please try again.'));
};

export const setSorting = ({ commit }, data) => commit(types.SET_SORTING, data);
