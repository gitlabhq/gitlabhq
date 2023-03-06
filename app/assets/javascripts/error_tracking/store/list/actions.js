import { createAlert } from '~/alert';
import Poll from '~/lib/utils/poll';
import { __ } from '~/locale';
import Service from '../../services';
import * as types from './mutation_types';

let eTagPoll;

export function startPolling({ state, commit, dispatch }) {
  commit(types.SET_LOADING, true);

  eTagPoll = new Poll({
    resource: Service,
    method: 'getSentryData',
    data: {
      endpoint: state.endpoint,
      params: {
        search_term: state.searchQuery,
        sort: state.sortField,
        cursor: state.cursor,
        issue_status: state.statusFilter,
      },
    },
    successCallback: ({ data }) => {
      if (!data) {
        return;
      }

      commit(types.SET_PAGINATION, data.pagination);
      commit(types.SET_ERRORS, data.errors);
      commit(types.SET_LOADING, false);
      dispatch('stopPolling');
    },
    errorCallback: () => {
      commit(types.SET_LOADING, false);
      createAlert({
        message: __('Failed to load errors from Sentry.'),
      });
    },
  });

  eTagPoll.makeRequest();
}

export const stopPolling = () => {
  if (eTagPoll) eTagPoll.stop();
};

export function restartPolling({ commit }) {
  commit(types.SET_ERRORS, []);
  commit(types.SET_LOADING, true);

  if (eTagPoll) eTagPoll.restart();
}

export function setIndexPath({ commit }, path) {
  commit(types.SET_INDEX_PATH, path);
}

export function loadRecentSearches({ commit }) {
  commit(types.LOAD_RECENT_SEARCHES);
}

export function addRecentSearch({ commit }, searchQuery) {
  commit(types.ADD_RECENT_SEARCH, searchQuery);
}

export function clearRecentSearches({ commit }) {
  commit(types.CLEAR_RECENT_SEARCHES);
}

export const searchByQuery = ({ commit, dispatch }, query) => {
  const searchQuery = query.trim();
  commit(types.SET_CURSOR, null);
  commit(types.SET_SEARCH_QUERY, searchQuery);
  commit(types.ADD_RECENT_SEARCH, searchQuery);
  dispatch('stopPolling');
  dispatch('startPolling');
};

export const filterByStatus = ({ commit, dispatch }, status) => {
  commit(types.SET_STATUS_FILTER, status);
  dispatch('stopPolling');
  dispatch('startPolling');
};

export const sortByField = ({ commit, dispatch }, field) => {
  commit(types.SET_CURSOR, null);
  commit(types.SET_SORT_FIELD, field);
  dispatch('stopPolling');
  dispatch('startPolling');
};

export const setEndpoint = ({ commit }, endpoint) => {
  commit(types.SET_ENDPOINT, endpoint);
};

export const fetchPaginatedResults = ({ commit, dispatch }, cursor) => {
  commit(types.SET_CURSOR, cursor);
  dispatch('stopPolling');
  dispatch('startPolling');
};

export const removeIgnoredResolvedErrors = ({ commit }, error) => {
  commit(types.REMOVE_IGNORED_RESOLVED_ERRORS, error);
};
