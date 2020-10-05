import * as types from './mutation_types';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { NEW_VERSION_FLAG } from '../../../constants';
import { mapFromScopesViewModel, mapStrategiesToRails } from '../helpers';

/**
 * Commits mutation to set the main endpoint
 * @param {String} endpoint
 */
export const setEndpoint = ({ commit }, endpoint) => commit(types.SET_ENDPOINT, endpoint);

/**
 * Commits mutation to set the feature flag path.
 * Used to redirect the user after form submission
 *
 * @param {String} path
 */
export const setPath = ({ commit }, path) => commit(types.SET_PATH, path);

/**
 * Handles the creation of a new feature flag.
 *
 * Will dispatch `requestCreateFeatureFlag`
 * Serializes the params and makes a post request
 * Dispatches an action acording to the request status.
 *
 * @param {Object} params
 */
export const createFeatureFlag = ({ state, dispatch }, params) => {
  dispatch('requestCreateFeatureFlag');

  return axios
    .post(
      state.endpoint,
      params.version === NEW_VERSION_FLAG
        ? mapStrategiesToRails(params)
        : mapFromScopesViewModel(params),
    )
    .then(() => {
      dispatch('receiveCreateFeatureFlagSuccess');
      visitUrl(state.path);
    })
    .catch(error => dispatch('receiveCreateFeatureFlagError', error.response.data));
};

export const requestCreateFeatureFlag = ({ commit }) => commit(types.REQUEST_CREATE_FEATURE_FLAG);
export const receiveCreateFeatureFlagSuccess = ({ commit }) =>
  commit(types.RECEIVE_CREATE_FEATURE_FLAG_SUCCESS);
export const receiveCreateFeatureFlagError = ({ commit }, error) =>
  commit(types.RECEIVE_CREATE_FEATURE_FLAG_ERROR, error);
