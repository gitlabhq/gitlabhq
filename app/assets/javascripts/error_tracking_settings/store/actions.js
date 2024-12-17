import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
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

  createAlert({
    message: `${__('There was an error saving your changes.')} ${message}`,
  });
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
      // Fixes a problem that refreshCurrentPage() does nothing when a hash is set.
      // eslint-disable-next-line no-restricted-globals
      history.pushState('', document.title, window.location.pathname + window.location.search);

      refreshCurrentPage();
    })
    .catch((err) => {
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

export const updateIntegrated = ({ commit }, integrated) => {
  commit(types.UPDATE_INTEGRATED, integrated);
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
