import * as types from './mutation_types';

export default {
  [types.RECEIVE_CREATE_USER_LIST_ERROR](state, error) {
    state.errorMessage = error;
  },
  [types.DISMISS_ERROR_ALERT](state) {
    state.errorMessage = '';
  },
};
