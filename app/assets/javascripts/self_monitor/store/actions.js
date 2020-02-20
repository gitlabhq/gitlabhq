import { __, s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import statusCodes from '~/lib/utils/http_status';
import { backOff } from '~/lib/utils/common_utils';
import * as types from './mutation_types';

const TWO_MINUTES = 120000;

function backOffRequest(makeRequestCallback) {
  return backOff((next, stop) => {
    makeRequestCallback()
      .then(resp => {
        if (resp.status === statusCodes.ACCEPTED) {
          next();
        } else {
          stop(resp);
        }
      })
      .catch(stop);
  }, TWO_MINUTES);
}

export const setSelfMonitor = ({ commit }, enabled) => commit(types.SET_ENABLED, enabled);

export const createProject = ({ dispatch }) => dispatch('requestCreateProject');

export const resetAlert = ({ commit }) => commit(types.SET_SHOW_ALERT, false);

export const requestCreateProject = ({ dispatch, state, commit }) => {
  commit(types.SET_LOADING, true);
  axios
    .post(state.createProjectEndpoint)
    .then(resp => {
      if (resp.status === statusCodes.ACCEPTED) {
        dispatch('requestCreateProjectStatus', resp.data.job_id);
      }
    })
    .catch(error => {
      dispatch('requestCreateProjectError', error);
    });
};

export const requestCreateProjectStatus = ({ dispatch, state }, jobId) => {
  backOffRequest(() => axios.get(state.createProjectStatusEndpoint, { params: { job_id: jobId } }))
    .then(resp => {
      if (resp.status === statusCodes.OK) {
        dispatch('requestCreateProjectSuccess', resp.data);
      }
    })
    .catch(error => {
      dispatch('requestCreateProjectError', error);
    });
};

export const requestCreateProjectSuccess = ({ commit, dispatch }, selfMonitorData) => {
  commit(types.SET_LOADING, false);
  commit(types.SET_PROJECT_URL, selfMonitorData.project_full_path);
  commit(types.SET_ALERT_CONTENT, {
    message: s__('SelfMonitoring|Self monitoring project has been successfully created.'),
    actionText: __('View project'),
    actionName: 'viewSelfMonitorProject',
  });
  commit(types.SET_SHOW_ALERT, true);
  commit(types.SET_PROJECT_CREATED, true);
  dispatch('setSelfMonitor', true);
};

export const requestCreateProjectError = ({ commit }, error) => {
  const { response } = error;
  const message = response.data && response.data.message ? response.data.message : '';

  commit(types.SET_ALERT_CONTENT, {
    message: `${__('There was an error saving your changes.')} ${message}`,
  });
  commit(types.SET_SHOW_ALERT, true);
  commit(types.SET_LOADING, false);
};

export const deleteProject = ({ dispatch }) => dispatch('requestDeleteProject');

export const requestDeleteProject = ({ dispatch, state, commit }) => {
  commit(types.SET_LOADING, true);
  axios
    .delete(state.deleteProjectEndpoint)
    .then(resp => {
      if (resp.status === statusCodes.ACCEPTED) {
        dispatch('requestDeleteProjectStatus', resp.data.job_id);
      }
    })
    .catch(error => {
      dispatch('requestDeleteProjectError', error);
    });
};

export const requestDeleteProjectStatus = ({ dispatch, state }, jobId) => {
  backOffRequest(() => axios.get(state.deleteProjectStatusEndpoint, { params: { job_id: jobId } }))
    .then(resp => {
      if (resp.status === statusCodes.OK) {
        dispatch('requestDeleteProjectSuccess', resp.data);
      }
    })
    .catch(error => {
      dispatch('requestDeleteProjectError', error);
    });
};

export const requestDeleteProjectSuccess = ({ commit }) => {
  commit(types.SET_PROJECT_URL, '');
  commit(types.SET_PROJECT_CREATED, false);
  commit(types.SET_ALERT_CONTENT, {
    message: s__('SelfMonitoring|Self monitoring project has been successfully deleted.'),
    actionText: __('Undo'),
    actionName: 'createProject',
  });
  commit(types.SET_SHOW_ALERT, true);
  commit(types.SET_LOADING, false);
};

export const requestDeleteProjectError = ({ commit }, error) => {
  const { response } = error;
  const message = response.data && response.data.message ? response.data.message : '';

  commit(types.SET_ALERT_CONTENT, {
    message: `${__('There was an error saving your changes.')} ${message}`,
  });
  commit(types.SET_LOADING, false);
};
