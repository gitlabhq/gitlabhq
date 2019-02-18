import Visibility from 'visibilityjs';
import * as types from './mutation_types';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import Poll from '~/lib/utils/poll';
import createFlash from '~/flash';
import { s__, sprintf } from '~/locale';
import axios from '~/lib/utils/axios_utils';

let eTagPoll;

export const clearJobsEtagPoll = () => {
  eTagPoll = null;
};
export const stopJobsPolling = () => {
  if (eTagPoll) eTagPoll.stop();
};
export const restartJobsPolling = () => {
  if (eTagPoll) eTagPoll.restart();
};

export const setInitialData = ({ commit }, data) => commit(types.SET_INITIAL_DATA, data);

export const requestRepos = ({ commit }, repos) => commit(types.REQUEST_REPOS, repos);
export const receiveReposSuccess = ({ commit }, repos) =>
  commit(types.RECEIVE_REPOS_SUCCESS, repos);
export const receiveReposError = ({ commit }) => commit(types.RECEIVE_REPOS_ERROR);
export const fetchRepos = ({ state, dispatch }) => {
  dispatch('requestRepos');

  return axios
    .get(state.reposPath)
    .then(({ data }) =>
      dispatch('receiveReposSuccess', convertObjectPropsToCamelCase(data, { deep: true })),
    )
    .then(() => dispatch('fetchJobs'))
    .catch(() => {
      createFlash(
        sprintf(s__('ImportProjects|Requesting your %{provider} repositories failed'), {
          provider: state.provider,
        }),
      );

      dispatch('receiveReposError');
    });
};

export const requestImport = ({ commit, state }, repoId) => {
  if (!state.reposBeingImported.includes(repoId)) commit(types.REQUEST_IMPORT, repoId);
};
export const receiveImportSuccess = ({ commit }, { importedProject, repoId }) =>
  commit(types.RECEIVE_IMPORT_SUCCESS, { importedProject, repoId });
export const receiveImportError = ({ commit }, repoId) =>
  commit(types.RECEIVE_IMPORT_ERROR, repoId);
export const fetchImport = ({ state, dispatch }, { newName, targetNamespace, repo }) => {
  dispatch('requestImport', repo.id);

  return axios
    .post(state.importPath, {
      ci_cd_only: state.ciCdOnly,
      new_name: newName,
      repo_id: repo.id,
      target_namespace: targetNamespace,
    })
    .then(({ data }) =>
      dispatch('receiveImportSuccess', {
        importedProject: convertObjectPropsToCamelCase(data, { deep: true }),
        repoId: repo.id,
      }),
    )
    .catch(() => {
      createFlash(s__('ImportProjects|Importing the project failed'));

      dispatch('receiveImportError', { repoId: repo.id });
    });
};

export const receiveJobsSuccess = ({ commit }, updatedProjects) =>
  commit(types.RECEIVE_JOBS_SUCCESS, updatedProjects);
export const fetchJobs = ({ state, dispatch }) => {
  if (eTagPoll) return;

  eTagPoll = new Poll({
    resource: {
      fetchJobs: () => axios.get(state.jobsPath),
    },
    method: 'fetchJobs',
    successCallback: ({ data }) =>
      dispatch('receiveJobsSuccess', convertObjectPropsToCamelCase(data, { deep: true })),
    errorCallback: () => createFlash(s__('ImportProjects|Updating the imported projects failed')),
  });

  if (!Visibility.hidden()) {
    eTagPoll.makeRequest();
  }

  Visibility.change(() => {
    if (!Visibility.hidden()) {
      dispatch('restartJobsPolling');
    } else {
      dispatch('stopJobsPolling');
    }
  });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
