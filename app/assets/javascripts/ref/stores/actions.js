import Api from '~/api';
import { REF_TYPE_BRANCHES, REF_TYPE_TAGS, REF_TYPE_COMMITS } from '../constants';
import * as types from './mutation_types';

export const setEnabledRefTypes = ({ commit }, refTypes) =>
  commit(types.SET_ENABLED_REF_TYPES, refTypes);

export const setParams = ({ commit }, params) => commit(types.SET_PARAMS, params);

export const setUseSymbolicRefNames = ({ commit }, useSymbolicRefNames) =>
  commit(types.SET_USE_SYMBOLIC_REF_NAMES, useSymbolicRefNames);

export const setProjectId = ({ commit }, projectId) => commit(types.SET_PROJECT_ID, projectId);

export const setSelectedRef = ({ commit }, selectedRef) =>
  commit(types.SET_SELECTED_REF, selectedRef);

export const search = ({ state, dispatch, commit }, query) => {
  commit(types.SET_QUERY, query);

  const dispatchIfRefTypeEnabled = (refType, action) => {
    if (state.enabledRefTypes.includes(refType)) {
      dispatch(action);
    }
  };
  dispatchIfRefTypeEnabled(REF_TYPE_BRANCHES, 'searchBranches');
  dispatchIfRefTypeEnabled(REF_TYPE_TAGS, 'searchTags');
  dispatchIfRefTypeEnabled(REF_TYPE_COMMITS, 'searchCommits');
};

export const searchBranches = ({ commit, state }) => {
  commit(types.REQUEST_START);

  Api.branches(state.projectId, state.query, state.params)
    .then((response) => {
      commit(types.RECEIVE_BRANCHES_SUCCESS, response);
    })
    .catch((error) => {
      commit(types.RECEIVE_BRANCHES_ERROR, error);
    })
    .finally(() => {
      commit(types.REQUEST_FINISH);
    });
};

export const searchTags = ({ commit, state }) => {
  commit(types.REQUEST_START);

  Api.tags(state.projectId, state.query)
    .then((response) => {
      commit(types.RECEIVE_TAGS_SUCCESS, response);
    })
    .catch((error) => {
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
      .then((response) => {
        commit(types.RECEIVE_COMMITS_SUCCESS, response);
      })
      .catch((error) => {
        commit(types.RECEIVE_COMMITS_ERROR, error);
      })
      .finally(() => {
        commit(types.REQUEST_FINISH);
      });
  } else {
    commit(types.RESET_COMMIT_MATCHES);
  }
};
