import Service from '../../services';
import * as types from './mutation_types';
import createFlash from '~/flash';
import Poll from '~/lib/utils/poll';
import { __, sprintf } from '~/locale';

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
      },
    },
    successCallback: ({ data }) => {
      if (!data) {
        return;
      }
      commit(types.SET_ERRORS, data.errors);
      commit(types.SET_LOADING, false);
      dispatch('stopPolling');
    },
    errorCallback: ({ response }) => {
      let errorMessage = '';
      if (response && response.data && response.data.message) {
        errorMessage = response.data.message;
      }
      commit(types.SET_LOADING, false);
      createFlash(
        sprintf(__(`Failed to load errors from Sentry. Error message: %{errorMessage}`), {
          errorMessage,
        }),
      );
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
  commit(types.SET_SEARCH_QUERY, searchQuery);
  commit(types.ADD_RECENT_SEARCH, searchQuery);
  dispatch('stopPolling');
  dispatch('startPolling');
};

export const sortByField = ({ commit, dispatch }, field) => {
  commit(types.SET_SORT_FIELD, field);
  dispatch('stopPolling');
  dispatch('startPolling');
};

export const setEndpoint = ({ commit }, endpoint) => {
  commit(types.SET_ENDPOINT, endpoint);
};

export default () => {};
