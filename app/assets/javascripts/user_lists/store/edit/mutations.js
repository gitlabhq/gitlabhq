import statuses from '../../constants/edit';
import * as types from './mutation_types';

export default {
  [types.REQUEST_USER_LIST](state) {
    state.status = statuses.LOADING;
  },
  [types.RECEIVE_USER_LIST_SUCCESS](state, userList) {
    state.status = statuses.SUCCESS;
    state.userList = userList;
  },
  [types.RECEIVE_USER_LIST_ERROR](state, error) {
    state.status = statuses.ERROR;
    state.errorMessage = error;
  },
  [types.DISMISS_ERROR_ALERT](state) {
    state.status = statuses.UNSYNCED;
  },
};
