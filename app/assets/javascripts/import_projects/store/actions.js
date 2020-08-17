import Visibility from 'visibilityjs';
import * as types from './mutation_types';
import { isProjectImportable } from '../utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import Poll from '~/lib/utils/poll';
import { visitUrl } from '~/lib/utils/url_utility';
import createFlash from '~/flash';
import { s__, sprintf } from '~/locale';
import axios from '~/lib/utils/axios_utils';

let eTagPoll;

const hasRedirectInError = e => e?.response?.data?.error?.redirect;
const redirectToUrlInError = e => visitUrl(e.response.data.error.redirect);
const pathWithFilter = ({ path, filter = '' }) => (filter ? `${path}?filter=${filter}` : path);

const isRequired = () => {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  throw new Error('param is required');
};

const clearJobsEtagPoll = () => {
  eTagPoll = null;
};

const stopJobsPolling = () => {
  if (eTagPoll) eTagPoll.stop();
};

const restartJobsPolling = () => {
  if (eTagPoll) eTagPoll.restart();
};

const setFilter = ({ commit }, filter) => commit(types.SET_FILTER, filter);

const setImportTarget = ({ commit }, { repoId, importTarget }) =>
  commit(types.SET_IMPORT_TARGET, { repoId, importTarget });

const importAll = ({ state, dispatch }) => {
  return Promise.all(
    state.repositories
      .filter(isProjectImportable)
      .map(r => dispatch('fetchImport', r.importSource.id)),
  );
};

const fetchReposFactory = (reposPath = isRequired()) => ({ state, dispatch, commit }) => {
  dispatch('stopJobsPolling');
  commit(types.REQUEST_REPOS);

  const { provider, filter } = state;

  return axios
    .get(pathWithFilter({ path: reposPath, filter }))
    .then(({ data }) =>
      commit(types.RECEIVE_REPOS_SUCCESS, convertObjectPropsToCamelCase(data, { deep: true })),
    )
    .then(() => dispatch('fetchJobs'))
    .catch(e => {
      if (hasRedirectInError(e)) {
        redirectToUrlInError(e);
      } else {
        createFlash(
          sprintf(s__('ImportProjects|Requesting your %{provider} repositories failed'), {
            provider,
          }),
        );

        commit(types.RECEIVE_REPOS_ERROR);
      }
    });
};

const fetchImportFactory = (importPath = isRequired()) => ({ state, commit, getters }, repoId) => {
  const { ciCdOnly } = state;
  const importTarget = getters.getImportTarget(repoId);

  commit(types.REQUEST_IMPORT, { repoId, importTarget });

  const { newName, targetNamespace } = importTarget;
  return axios
    .post(importPath, {
      repo_id: repoId,
      ci_cd_only: ciCdOnly,
      new_name: newName,
      target_namespace: targetNamespace,
    })
    .then(({ data }) =>
      commit(types.RECEIVE_IMPORT_SUCCESS, {
        importedProject: convertObjectPropsToCamelCase(data, { deep: true }),
        repoId,
      }),
    )
    .catch(e => {
      const serverErrorMessage = e?.response?.data?.errors;
      const flashMessage = serverErrorMessage
        ? sprintf(
            s__('ImportProjects|Importing the project failed: %{reason}'),
            {
              reason: serverErrorMessage,
            },
            false,
          )
        : s__('ImportProjects|Importing the project failed');

      createFlash(flashMessage);

      commit(types.RECEIVE_IMPORT_ERROR, repoId);
    });
};

export const fetchJobsFactory = (jobsPath = isRequired()) => ({ state, commit, dispatch }) => {
  const { filter } = state;

  if (eTagPoll) {
    stopJobsPolling();
    clearJobsEtagPoll();
  }

  eTagPoll = new Poll({
    resource: {
      fetchJobs: () => axios.get(pathWithFilter({ path: jobsPath, filter })),
    },
    method: 'fetchJobs',
    successCallback: ({ data }) =>
      commit(types.RECEIVE_JOBS_SUCCESS, convertObjectPropsToCamelCase(data, { deep: true })),
    errorCallback: e => {
      if (hasRedirectInError(e)) {
        redirectToUrlInError(e);
      } else {
        createFlash(s__('ImportProjects|Update of imported projects with realtime changes failed'));
      }
    },
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

const fetchNamespacesFactory = (namespacesPath = isRequired()) => ({ commit }) => {
  commit(types.REQUEST_NAMESPACES);
  axios
    .get(namespacesPath)
    .then(({ data }) =>
      commit(types.RECEIVE_NAMESPACES_SUCCESS, convertObjectPropsToCamelCase(data, { deep: true })),
    )
    .catch(() => {
      createFlash(s__('ImportProjects|Requesting namespaces failed'));

      commit(types.RECEIVE_NAMESPACES_ERROR);
    });
};

export default ({ endpoints = isRequired() }) => ({
  clearJobsEtagPoll,
  stopJobsPolling,
  restartJobsPolling,
  setFilter,
  setImportTarget,
  importAll,
  fetchRepos: fetchReposFactory(endpoints.reposPath),
  fetchImport: fetchImportFactory(endpoints.importPath),
  fetchJobs: fetchJobsFactory(endpoints.jobsPath),
  fetchNamespaces: fetchNamespacesFactory(endpoints.namespacesPath),
});
