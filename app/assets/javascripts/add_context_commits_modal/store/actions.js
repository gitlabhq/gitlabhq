import { uniqBy, orderBy } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import Api from '~/api';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import { joinPaths } from '~/lib/utils/url_utility';
import { ACTIVE_AND_BLOCKED_USER_STATES } from '~/users_select/constants';
import * as types from './mutation_types';

export const setBaseConfig = ({ commit }, options) => {
  commit(types.SET_BASE_CONFIG, options);
};

export const setTabIndex = ({ commit }, tabIndex) => commit(types.SET_TABINDEX, tabIndex);

export const searchCommits = ({ dispatch, commit, state }, search = {}) => {
  commit(types.FETCH_COMMITS);

  let params = {};
  if (search) {
    params = {
      params: {
        ...search,
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
      if (!search) {
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
  let commits = uniqBy(data, 'short_id');
  commits = orderBy(data, (c) => new Date(c.committed_date), ['desc']);
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
        createAlert({
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
        createAlert({
          message: s__('ContextCommits|Failed to delete context commits. Please try again.'),
        });
      }

      return false;
    });

export const setSelectedCommits = ({ commit }, selected) => {
  let selectedCommits = uniqBy(selected, 'short_id');
  selectedCommits = orderBy(
    selectedCommits,
    (selectedCommit) => new Date(selectedCommit.committed_date),
    ['desc'],
  );
  commit(types.SET_SELECTED_COMMITS, selectedCommits);
};

export const fetchAuthors = ({ dispatch, state }, author = null) => {
  const { projectId } = state;
  return axios
    .get(joinPaths(gon.relative_url_root || '', '/-/autocomplete/users.json'), {
      params: {
        project_id: projectId,
        states: ACTIVE_AND_BLOCKED_USER_STATES,
        search: author,
      },
    })
    .then(({ data }) => data)
    .catch((error) => {
      Sentry.captureException(error);
      dispatch('receiveAuthorsError');
    });
};

export const setSearchText = ({ commit }, searchText) => commit(types.SET_SEARCH_TEXT, searchText);

export const setToRemoveCommits = ({ commit }, data) => commit(types.SET_TO_REMOVE_COMMITS, data);

export const resetModalState = ({ commit }) => commit(types.RESET_MODAL_STATE);
