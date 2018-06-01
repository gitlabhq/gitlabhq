import { states } from './constants';

export default () => ({
  created: {
    isLoading: false,
    mergeRequests: [],
  },
  assigned: {
    isLoading: false,
    mergeRequests: [],
  },
  state: states.opened,
});
