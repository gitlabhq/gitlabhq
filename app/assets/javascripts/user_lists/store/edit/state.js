import statuses from '../../constants/edit';

export default ({ projectId = '', userListIid = '' }) => ({
  status: statuses.LOADING,
  projectId,
  userListIid,
  userList: null,
  errorMessage: [],
});
