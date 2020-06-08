import Visibility from 'visibilityjs';
import * as types from './mutation_types';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import Poll from '~/lib/utils/poll';
import createFlash from '~/flash';
import { s__, sprintf } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { jobsPathWithFilter, reposPathWithFilter } from './getters';

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

export const setFilter = ({ commit }, filter) => commit(types.SET_FILTER, filter);

export const fetchRepos = ({ state, dispatch, commit }) => {
  dispatch('stopJobsPolling');
  commit(types.REQUEST_REPOS);

  const { provider } = state;

  return axios
    .get(reposPathWithFilter(state))
    .then(({ data }) =>
      commit(types.RECEIVE_REPOS_SUCCESS, convertObjectPropsToCamelCase(data, { deep: true })),
    )
    .then(() => dispatch('fetchJobs'))
    .catch(() => {
      createFlash(
        sprintf(s__('ImportProjects|Requesting your %{provider} repositories failed'), {
          provider,
        }),
      );

      commit(types.RECEIVE_REPOS_ERROR);
    });
};

export const fetchImport = ({ state, commit }, { newName, targetNamespace, repo }) => {
  if (!state.reposBeingImported.includes(repo.id)) {
    commit(types.REQUEST_IMPORT, repo.id);
  }

  return axios
    .post(state.importPath, {
      ci_cd_only: state.ciCdOnly,
      new_name: newName,
      repo_id: repo.id,
      target_namespace: targetNamespace,
    })
    .then(({ data }) =>
      commit(types.RECEIVE_IMPORT_SUCCESS, {
        importedProject: convertObjectPropsToCamelCase(data, { deep: true }),
        repoId: repo.id,
      }),
    )
    .catch(() => {
      createFlash(s__('ImportProjects|Importing the project failed'));

      commit(types.RECEIVE_IMPORT_ERROR, repo.id);
    });
};

export const receiveJobsSuccess = ({ commit }, updatedProjects) =>
  commit(types.RECEIVE_JOBS_SUCCESS, updatedProjects);

export const fetchJobs = ({ state, commit, dispatch }) => {
  const { filter } = state;

  if (eTagPoll) {
    stopJobsPolling();
    clearJobsEtagPoll();
  }

  eTagPoll = new Poll({
    resource: {
      fetchJobs: () => axios.get(jobsPathWithFilter(state)),
    },
    method: 'fetchJobs',
    successCallback: ({ data }) =>
      commit(types.RECEIVE_JOBS_SUCCESS, convertObjectPropsToCamelCase(data, { deep: true })),
    errorCallback: () =>
      createFlash(s__('ImportProjects|Update of imported projects with realtime changes failed')),
    data: { filter },
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
