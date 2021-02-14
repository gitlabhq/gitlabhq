import * as types from './mutation_types';
import statuses from './status';

export default {
  [types.FETCH_USER_LISTS](state) {
    state.status = statuses.LOADING;
  },
  [types.RECEIVE_USER_LISTS_SUCCESS](state, lists) {
    state.userLists = lists;
    state.status = statuses.IDLE;
  },
  [types.RECEIVE_USER_LISTS_ERROR](state, error) {
    state.error = error;
    state.status = statuses.ERROR;
  },
  [types.SET_FILTER](state, filter) {
    state.filter = filter;
  },
};
