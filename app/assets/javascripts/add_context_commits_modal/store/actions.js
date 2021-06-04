import _ from 'lodash';
import Api from '~/api';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import * as types from './mutation_types';

export const setBaseConfig = ({ commit }, options) => {
  commit(types.SET_BASE_CONFIG, options);
};

export const setTabIndex = ({ commit }, tabIndex) => commit(types.SET_TABINDEX, tabIndex);

export const searchCommits = ({ dispatch, commit, state }, searchText) => {
  commit(types.FETCH_COMMITS);

  let params = {};
  if (searchText) {
    params = {
      params: {
        search: searchText,
        per_page: 40,
      },
    };
  }

  return axios
    .get(state.contextCommitsPath, params)
    .then(({ data }) => {
      let commits = data.map((o) => ({ ...o, isSelected: false }));
      commits = commits.map((c) => {
        const isPresent = state.selectedCommits.find(
          (selectedCommit) => selectedCommit.short_id === c.short_id && selectedCommit.isSelected,
        );
        if (isPresent) {
          return { ...c, isSelected: true };
        }
        return c;
      });
      if (!searchText) {
        dispatch('setCommits', { commits: [...commits, ...state.contextCommits] });
      } else {
        dispatch('setCommits', { commits });
      }
    })
    .catch(() => {
      commit(types.FETCH_COMMITS_ERROR);
    });
};

export const setCommits = ({ commit }, { commits: data, silentAddition = false }) => {
  let commits = _.uniqBy(data, 'short_id');
  commits = _.orderBy(data, (c) => new Date(c.committed_date), ['desc']);
  if (silentAddition) {
    commit(types.SET_COMMITS_SILENT, commits);
  } else {
    commit(types.SET_COMMITS, commits);
  }
};

export const createContextCommits = ({ state }, { commits, forceReload = false }) =>
  Api.createContextCommits(state.projectId, state.mergeRequestIid, {
    commits: commits.map((commit) => commit.short_id),
  })
    .then(() => {
      if (forceReload) {
        window.location.reload();
      }

      return true;
    })
    .catch(() => {
      if (forceReload) {
        createFlash({
          message: s__('ContextCommits|Failed to create context commits. Please try again.'),
        });
      }

      return false;
    });

export const fetchContextCommits = ({ dispatch, commit, state }) => {
  commit(types.FETCH_CONTEXT_COMMITS);
  return Api.allContextCommits(state.projectId, state.mergeRequestIid)
    .then(({ data }) => {
      const contextCommits = data.map((o) => ({ ...o, isSelected: true }));
      dispatch('setContextCommits', contextCommits);
      dispatch('setCommits', {
        commits: [...state.commits, ...contextCommits],
        silentAddition: true,
      });
      dispatch('setSelectedCommits', contextCommits);
    })
    .catch(() => {
      commit(types.FETCH_CONTEXT_COMMITS_ERROR);
    });
};

export const setContextCommits = ({ commit }, data) => {
  commit(types.SET_CONTEXT_COMMITS, data);
};

export const removeContextCommits = ({ state }, forceReload = false) =>
  Api.removeContextCommits(state.projectId, state.mergeRequestIid, {
    commits: state.toRemoveCommits,
  })
    .then(() => {
      if (forceReload) {
        window.location.reload();
      }

      return true;
    })
    .catch(() => {
      if (forceReload) {
        createFlash({
          message: s__('ContextCommits|Failed to delete context commits. Please try again.'),
        });
      }

      return false;
    });

export const setSelectedCommits = ({ commit }, selected) => {
  let selectedCommits = _.uniqBy(selected, 'short_id');
  selectedCommits = _.orderBy(
    selectedCommits,
    (selectedCommit) => new Date(selectedCommit.committed_date),
    ['desc'],
  );
  commit(types.SET_SELECTED_COMMITS, selectedCommits);
};

export const setSearchText = ({ commit }, searchText) => commit(types.SET_SEARCH_TEXT, searchText);

export const setToRemoveCommits = ({ commit }, data) => commit(types.SET_TO_REMOVE_COMMITS, data);

export const resetModalState = ({ commit }) => commit(types.RESET_MODAL_STATE);
