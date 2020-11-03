import statuses from './status';

export default ({ projectId }) => ({
  projectId,
  userLists: [],
  filter: '',
  status: statuses.START,
  error: '',
});
