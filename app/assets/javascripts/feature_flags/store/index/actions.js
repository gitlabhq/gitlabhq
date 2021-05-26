import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';

export const setFeatureFlagsOptions = ({ commit }, options) =>
  commit(types.SET_FEATURE_FLAGS_OPTIONS, options);

export const fetchFeatureFlags = ({ state, dispatch }) => {
  dispatch('requestFeatureFlags');

  axios
    .get(state.endpoint, {
      params: state.options,
    })
    .then((response) =>
      dispatch('receiveFeatureFlagsSuccess', {
        data: response.data || {},
        headers: response.headers,
      }),
    )
    .catch(() => dispatch('receiveFeatureFlagsError'));
};

export const requestFeatureFlags = ({ commit }) => commit(types.REQUEST_FEATURE_FLAGS);
export const receiveFeatureFlagsSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_FEATURE_FLAGS_SUCCESS, response);
export const receiveFeatureFlagsError = ({ commit }) => commit(types.RECEIVE_FEATURE_FLAGS_ERROR);

export const toggleFeatureFlag = ({ dispatch }, flag) => {
  dispatch('updateFeatureFlag', flag);

  axios
    .put(flag.update_path, {
      operations_feature_flag: flag,
    })
    .then((response) => dispatch('receiveUpdateFeatureFlagSuccess', response.data))
    .catch(() => dispatch('receiveUpdateFeatureFlagError', flag.id));
};

export const updateFeatureFlag = ({ commit }, flag) => commit(types.UPDATE_FEATURE_FLAG, flag);

export const receiveUpdateFeatureFlagSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS, data);
export const receiveUpdateFeatureFlagError = ({ commit }, id) =>
  commit(types.RECEIVE_UPDATE_FEATURE_FLAG_ERROR, id);

export const rotateInstanceId = ({ state, dispatch }) => {
  dispatch('requestRotateInstanceId');

  axios
    .post(state.rotateEndpoint)
    .then(({ data = {}, headers }) => dispatch('receiveRotateInstanceIdSuccess', { data, headers }))
    .catch(() => dispatch('receiveRotateInstanceIdError'));
};

export const requestRotateInstanceId = ({ commit }) => commit(types.REQUEST_ROTATE_INSTANCE_ID);
export const receiveRotateInstanceIdSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_ROTATE_INSTANCE_ID_SUCCESS, response);
export const receiveRotateInstanceIdError = ({ commit }) =>
  commit(types.RECEIVE_ROTATE_INSTANCE_ID_ERROR);

export const clearAlert = ({ commit }, index) => {
  commit(types.RECEIVE_CLEAR_ALERT, index);
};
