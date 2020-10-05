import { states } from '../../constants/show';

export default ({ projectId = '', userListIid = '' }) => ({
  state: states.LOADING,
  projectId,
  userListIid,
  userIds: [],
  userList: null,
});
