import { states } from '../../constants/show';
import { parseUserIds } from '../utils';
import * as types from './mutation_types';

export default {
  [types.REQUEST_USER_LIST](state) {
    state.state = states.LOADING;
  },
  [types.RECEIVE_USER_LIST_SUCCESS](state, userList) {
    state.state = states.SUCCESS;
    state.userIds = userList.user_xids?.length > 0 ? parseUserIds(userList.user_xids) : [];
    state.userList = userList;
  },
  [types.RECEIVE_USER_LIST_ERROR](state) {
    state.state = states.ERROR;
  },
  [types.DISMISS_ERROR_ALERT](state) {
    state.state = states.ERROR_DISMISSED;
  },
  [types.ADD_USER_IDS](state, ids) {
    state.userIds = [
      ...state.userIds,
      ...parseUserIds(ids).filter((id) => id && !state.userIds.includes(id)),
    ];
  },
  [types.REMOVE_USER_ID](state, id) {
    state.userIds = state.userIds.filter((uid) => uid !== id);
  },
};
