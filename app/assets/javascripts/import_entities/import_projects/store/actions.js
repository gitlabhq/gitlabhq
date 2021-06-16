import Visibility from 'visibilityjs';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import httpStatusCodes from '~/lib/utils/http_status';
import Poll from '~/lib/utils/poll';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { visitUrl, objectToQuery } from '~/lib/utils/url_utility';
import { s__, sprintf } from '~/locale';
import { isProjectImportable } from '../utils';
import * as types from './mutation_types';

let eTagPoll;

const hasRedirectInError = (e) => e?.response?.data?.error?.redirect;
const redirectToUrlInError = (e) => visitUrl(e.response.data.error.redirect);
const tooManyRequests = (e) => e.response.status === httpStatusCodes.TOO_MANY_REQUESTS;
const pathWithParams = ({ path, ...params }) => {
  const filteredParams = Object.fromEntries(
    Object.entries(params).filter(([, value]) => value !== ''),
  );
  const queryString = objectToQuery(filteredParams);
  return queryString ? `${path}?${queryString}` : path;
};

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

const setImportTarget = ({ commit }, { repoId, importTarget }) =>
  commit(types.SET_IMPORT_TARGET, { repoId, importTarget });

const importAll = ({ state, dispatch }) => {
  return Promise.all(
    state.repositories
      .filter(isProjectImportable)
      .map((r) => dispatch('fetchImport', r.importSource.id)),
  );
};

const fetchReposFactory = ({ reposPath = isRequired() }) => ({ state, commit }) => {
  const nextPage = state.pageInfo.page + 1;
  commit(types.SET_PAGE, nextPage);
  commit(types.REQUEST_REPOS);

  const { provider, filter } = state;

  return axios
    .get(
      pathWithParams({
        path: reposPath,
        filter: filter ?? '',
        page: nextPage === 1 ? '' : nextPage.toString(),
      }),
    )
    .then(({ data }) => {
      commit(types.RECEIVE_REPOS_SUCCESS, convertObjectPropsToCamelCase(data, { deep: true }));
    })
    .catch((e) => {
      commit(types.SET_PAGE, nextPage - 1);

      if (hasRedirectInError(e)) {
        redirectToUrlInError(e);
      } else if (tooManyRequests(e)) {
        createFlash({
          message: sprintf(s__('ImportProjects|%{provider} rate limit exceeded. Try again later'), {
            provider: capitalizeFirstCharacter(provider),
          }),
        });

        commit(types.RECEIVE_REPOS_ERROR);
      } else {
        createFlash({
          message: sprintf(s__('ImportProjects|Requesting your %{provider} repositories failed'), {
            provider,
          }),
        });

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
    .then(({ data }) => {
      commit(types.RECEIVE_IMPORT_SUCCESS, {
        importedProject: convertObjectPropsToCamelCase(data, { deep: true }),
        repoId,
      });
    })
    .catch((e) => {
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

      createFlash({
        message: flashMessage,
      });

      commit(types.RECEIVE_IMPORT_ERROR, repoId);
    });
};

export const fetchJobsFactory = (jobsPath = isRequired()) => ({ state, commit, dispatch }) => {
  if (eTagPoll) {
    stopJobsPolling();
    clearJobsEtagPoll();
  }

  eTagPoll = new Poll({
    resource: {
      fetchJobs: () => axios.get(pathWithParams({ path: jobsPath, filter: state.filter })),
    },
    method: 'fetchJobs',
    successCallback: ({ data }) =>
      commit(types.RECEIVE_JOBS_SUCCESS, convertObjectPropsToCamelCase(data, { deep: true })),
    errorCallback: (e) => {
      if (hasRedirectInError(e)) {
        redirectToUrlInError(e);
      } else {
        createFlash({
          message: s__('ImportProjects|Update of imported projects with realtime changes failed'),
        });
      }
    },
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
      createFlash({
        message: s__('ImportProjects|Requesting namespaces failed'),
      });

      commit(types.RECEIVE_NAMESPACES_ERROR);
    });
};

const setFilter = ({ commit, dispatch }, filter) => {
  commit(types.SET_FILTER, filter);

  return dispatch('fetchRepos');
};

export default ({ endpoints = isRequired() }) => ({
  clearJobsEtagPoll,
  stopJobsPolling,
  restartJobsPolling,
  setFilter,
  setImportTarget,
  importAll,
  fetchRepos: fetchReposFactory({ reposPath: endpoints.reposPath }),
  fetchImport: fetchImportFactory(endpoints.importPath),
  fetchJobs: fetchJobsFactory(endpoints.jobsPath),
  fetchNamespaces: fetchNamespacesFactory(endpoints.namespacesPath),
});
