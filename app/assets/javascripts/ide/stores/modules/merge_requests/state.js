import { scopes, states } from './constants';

export default () => ({
  isLoading: false,
  mergeRequests: [],
  scope: scopes.assignedToMe,
  state: states.opened,
});
