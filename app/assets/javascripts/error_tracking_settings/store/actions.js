import { __ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import createFlash from '~/flash';
import { transformFrontendSettings } from '../utils';
import * as types from './mutation_types';

export const requestProjects = ({ commit }) => {
  commit(types.SET_PROJECTS_LOADING, true);
  commit(types.RESET_CONNECT);
};

export const receiveProjectsSuccess = ({ commit }, projects) => {
  commit(types.UPDATE_CONNECT_SUCCESS);
  commit(types.RECEIVE_PROJECTS, projects);
  commit(types.SET_PROJECTS_LOADING, false);
};

export const receiveProjectsError = ({ commit }) => {
  commit(types.UPDATE_CONNECT_ERROR);
  commit(types.CLEAR_PROJECTS);
  commit(types.SET_PROJECTS_LOADING, false);
};

export const fetchProjects = ({ dispatch, state }) => {
  dispatch('requestProjects');
  return axios
    .get(state.listProjectsEndpoint, {
      params: {
        api_host: state.apiHost,
        token: state.token,
      },
    })
    .then(({ data: { projects } }) => {
      dispatch('receiveProjectsSuccess', projects);
    })
    .catch(() => {
      dispatch('receiveProjectsError');
    });
};

export const requestSettings = ({ commit }) => {
  commit(types.UPDATE_SETTINGS_LOADING, true);
};

export const receiveSettingsError = ({ commit }, { response = {} }) => {
  const message = response.data && response.data.message ? response.data.message : '';

  createFlash(`${__('There was an error saving your changes.')} ${message}`, 'alert');
  commit(types.UPDATE_SETTINGS_LOADING, false);
};

export const updateSettings = ({ dispatch, state }) => {
  dispatch('requestSettings');
  return axios
    .patch(state.operationsSettingsEndpoint, {
      project: {
        error_tracking_setting_attributes: {
          ...transformFrontendSettings(state),
        },
      },
    })
    .then(() => {
      refreshCurrentPage();
    })
    .catch(err => {
      dispatch('receiveSettingsError', err);
    });
};

export const updateApiHost = ({ commit }, apiHost) => {
  commit(types.UPDATE_API_HOST, apiHost);
  commit(types.RESET_CONNECT);
};

export const updateEnabled = ({ commit }, enabled) => {
  commit(types.UPDATE_ENABLED, enabled);
};

export const updateToken = ({ commit }, token) => {
  commit(types.UPDATE_TOKEN, token);
  commit(types.RESET_CONNECT);
};

export const updateSelectedProject = ({ commit }, selectedProject) => {
  commit(types.UPDATE_SELECTED_PROJECT, selectedProject);
};

export const setInitialState = ({ commit }, data) => {
  commit(types.SET_INITIAL_STATE, data);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
