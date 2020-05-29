import * as types from './mutation_types';

export default {
  [types.START_LOADING](state) {
    state.isLoading = true;
    state.isError = false;
  },
  [types.SET_ERROR](state, { message }) {
    state.isLoading = false;
    state.isError = true;
    state.message = message;
  },
  [types.SET_SUCCESS](state) {
    state.isLoading = false;
    state.isError = false;
    state.isStarted = true;
  },
  [types.STOP](state) {
    state.isLoading = false;
    state.isStarted = false;
  },
};
