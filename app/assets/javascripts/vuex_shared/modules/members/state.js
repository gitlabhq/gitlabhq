export default ({
  members,
  sourceId,
  currentUserId,
  tableFields,
  memberPath,
  requestFormatter,
}) => ({
  members,
  sourceId,
  currentUserId,
  tableFields,
  memberPath,
  requestFormatter,
  showError: false,
  errorMessage: '',
  removeGroupLinkModalVisible: false,
  groupLinkToRemove: null,
});
