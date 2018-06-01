import { scopes, states } from './constants';

export default () => ({
  isLoading: false,
  mergeRequests: [],
  scope: scopes.createdByMe,
  state: states.opened,
});
