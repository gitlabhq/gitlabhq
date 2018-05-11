import { scopes } from './constants';

export default () => ({
  isLoading: false,
  mergeRequests: [],
  scope: scopes.assignedToMe,
});
