import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { mapStrategiesToRails } from '../helpers';
import * as types from './mutation_types';

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
    .post(state.endpoint, mapStrategiesToRails(params))
    .then(() => {
      dispatch('receiveCreateFeatureFlagSuccess');
      visitUrl(state.path);
    })
    .catch((error) => dispatch('receiveCreateFeatureFlagError', error.response.data));
};

export const requestCreateFeatureFlag = ({ commit }) => commit(types.REQUEST_CREATE_FEATURE_FLAG);
export const receiveCreateFeatureFlagSuccess = ({ commit }) =>
  commit(types.RECEIVE_CREATE_FEATURE_FLAG_SUCCESS);
export const receiveCreateFeatureFlagError = ({ commit }, error) =>
  commit(types.RECEIVE_CREATE_FEATURE_FLAG_ERROR, error);
