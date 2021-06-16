import createFlash from '~/flash';
import { __ } from '~/locale';
import { PAGE_SIZE } from '~/releases/constants';
import allReleasesQuery from '~/releases/graphql/queries/all_releases.query.graphql';
import { gqClient, convertAllReleasesGraphQLResponse } from '~/releases/util';
import * as types from './mutation_types';

/**
 * Gets a paginated list of releases from the GraphQL endpoint
 *
 * @param {Object} vuexParams
 * @param {Object} actionParams
 * @param {String} [actionParams.before] A GraphQL cursor. If provided,
 * the items returned will proceed the provided cursor.
 * @param {String} [actionParams.after] A GraphQL cursor. If provided,
 * the items returned will follow the provided cursor.
 */
export const fetchReleases = ({ dispatch, commit, state }, { before, after }) => {
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
      'Both a `before` and an `after` parameter were provided to fetchReleases. These parameters cannot be used together.',
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
    .then((response) => {
      const { data, paginationInfo: pageInfo } = convertAllReleasesGraphQLResponse(response);

      commit(types.RECEIVE_RELEASES_SUCCESS, {
        data,
        pageInfo,
      });
    })
    .catch(() => dispatch('receiveReleasesError'));
};

export const receiveReleasesError = ({ commit }) => {
  commit(types.RECEIVE_RELEASES_ERROR);
  createFlash({
    message: __('An error occurred while fetching the releases. Please try again.'),
  });
};

export const setSorting = ({ commit }, data) => commit(types.SET_SORTING, data);
