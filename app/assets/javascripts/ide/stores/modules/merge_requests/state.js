import { states } from './constants';

export default () => ({
  isLoading: false,
  mergeRequests: [],
  state: states.opened,
});
