import Api from '~/api';
import * as types from './mutation_types';

export const setProjectId = ({ commit }, projectId) => commit(types.SET_PROJECT_ID, projectId);

export const setSelectedRef = ({ commit }, selectedRef) =>
  commit(types.SET_SELECTED_REF, selectedRef);

export const search = ({ dispatch, commit }, query) => {
  commit(types.SET_QUERY, query);

  dispatch('searchBranches');
  dispatch('searchTags');
  dispatch('searchCommits');
};

export const searchBranches = ({ commit, state }) => {
  commit(types.REQUEST_START);

  Api.branches(state.projectId, state.query)
    .then(response => {
      commit(types.RECEIVE_BRANCHES_SUCCESS, response);
    })
    .catch(error => {
      commit(types.RECEIVE_BRANCHES_ERROR, error);
    })
    .finally(() => {
      commit(types.REQUEST_FINISH);
    });
};

export const searchTags = ({ commit, state }) => {
  commit(types.REQUEST_START);

  Api.tags(state.projectId, state.query)
    .then(response => {
      commit(types.RECEIVE_TAGS_SUCCESS, response);
    })
    .catch(error => {
      commit(types.RECEIVE_TAGS_ERROR, error);
    })
    .finally(() => {
      commit(types.REQUEST_FINISH);
    });
};

export const searchCommits = ({ commit, state, getters }) => {
  // Only query the Commit API if the search query looks like a commit SHA
  if (getters.isQueryPossiblyASha) {
    commit(types.REQUEST_START);

    Api.commit(state.projectId, state.query)
      .then(response => {
        commit(types.RECEIVE_COMMITS_SUCCESS, response);
      })
      .catch(error => {
        commit(types.RECEIVE_COMMITS_ERROR, error);
      })
      .finally(() => {
        commit(types.REQUEST_FINISH);
      });
  } else {
    commit(types.RESET_COMMIT_MATCHES);
  }
};
