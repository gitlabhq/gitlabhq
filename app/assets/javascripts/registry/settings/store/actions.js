import Api from '~/api';
import createFlash from '~/flash';
import {
  FETCH_SETTINGS_ERROR_MESSAGE,
  UPDATE_SETTINGS_ERROR_MESSAGE,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
} from '../constants';
import * as types from './mutation_types';

export const setInitialState = ({ commit }, data) => commit(types.SET_INITIAL_STATE, data);
export const updateSettings = ({ commit }, data) => commit(types.UPDATE_SETTINGS, data);
export const toggleLoading = ({ commit }) => commit(types.TOGGLE_LOADING);
export const receiveSettingsSuccess = ({ commit }, data = {}) => commit(types.SET_SETTINGS, data);
export const receiveSettingsError = () => createFlash(FETCH_SETTINGS_ERROR_MESSAGE);
export const updateSettingsError = () => createFlash(UPDATE_SETTINGS_ERROR_MESSAGE);
export const resetSettings = ({ commit }) => commit(types.RESET_SETTINGS);

export const fetchSettings = ({ dispatch, state }) => {
  dispatch('toggleLoading');
  return Api.project(state.projectId)
    .then(({ tag_expiration_policies }) =>
      dispatch('receiveSettingsSuccess', tag_expiration_policies),
    )
    .catch(() => dispatch('receiveSettingsError'))
    .finally(() => dispatch('toggleLoading'));
};

export const saveSettings = ({ dispatch, state }) => {
  dispatch('toggleLoading');
  return Api.updateProject(state.projectId, { tag_expiration_policies: state.settings })
    .then(({ tag_expiration_policies }) => {
      dispatch('receiveSettingsSuccess', tag_expiration_policies);
      createFlash(UPDATE_SETTINGS_SUCCESS_MESSAGE);
    })
    .catch(() => dispatch('updateSettingsError'))
    .finally(() => dispatch('toggleLoading'));
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
