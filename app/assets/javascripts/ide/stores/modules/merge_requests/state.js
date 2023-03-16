import { STATUS_OPEN } from '~/issues/constants';

export default () => ({
  isLoading: false,
  mergeRequests: [],
  state: STATUS_OPEN,
});
