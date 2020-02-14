import * as types from './mutation_types';

export default {
  [types.SET_INITIAL_STATE](state, initialState) {
    Object.keys(state).forEach(key => {
      state[key] = initialState[key];
    });
  },

  [types.REQUEST_RELEASE](state) {
    state.isFetchingRelease = true;
  },
  [types.RECEIVE_RELEASE_SUCCESS](state, data) {
    state.fetchError = undefined;
    state.isFetchingRelease = false;
    state.release = data;
  },
  [types.RECEIVE_RELEASE_ERROR](state, error) {
    state.fetchError = error;
    state.isFetchingRelease = false;
    state.release = undefined;
  },

  [types.UPDATE_RELEASE_TITLE](state, title) {
    state.release.name = title;
  },
  [types.UPDATE_RELEASE_NOTES](state, notes) {
    state.release.description = notes;
  },

  [types.REQUEST_UPDATE_RELEASE](state) {
    state.isUpdatingRelease = true;
  },
  [types.RECEIVE_UPDATE_RELEASE_SUCCESS](state) {
    state.updateError = undefined;
    state.isUpdatingRelease = false;
  },
  [types.RECEIVE_UPDATE_RELEASE_ERROR](state, error) {
    state.updateError = error;
    state.isUpdatingRelease = false;
  },
};
