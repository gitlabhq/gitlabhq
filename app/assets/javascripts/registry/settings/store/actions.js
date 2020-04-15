import Api from '~/api';
import * as types from './mutation_types';

export const setInitialState = ({ commit }, data) => commit(types.SET_INITIAL_STATE, data);
export const updateSettings = ({ commit }, data) => commit(types.UPDATE_SETTINGS, data);
export const toggleLoading = ({ commit }) => commit(types.TOGGLE_LOADING);
export const receiveSettingsSuccess = ({ commit }, data) => {
  commit(types.SET_SETTINGS, data);
};
export const resetSettings = ({ commit }) => commit(types.RESET_SETTINGS);

export const fetchSettings = ({ dispatch, state }) => {
  dispatch('toggleLoading');
  return Api.project(state.projectId)
    .then(({ data: { container_expiration_policy } }) =>
      dispatch('receiveSettingsSuccess', container_expiration_policy),
    )
    .finally(() => dispatch('toggleLoading'));
};

export const saveSettings = ({ dispatch, state }) => {
  dispatch('toggleLoading');
  return Api.updateProject(state.projectId, {
    container_expiration_policy_attributes: state.settings,
  })
    .then(({ data: { container_expiration_policy } }) =>
      dispatch('receiveSettingsSuccess', container_expiration_policy),
    )
    .finally(() => dispatch('toggleLoading'));
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
