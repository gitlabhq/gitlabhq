import { LEGACY_FLAG } from '../../../constants';

export default () => ({
  endpoint: null,
  path: null,
  isSendingRequest: false,
  error: [],

  name: null,
  description: null,
  scopes: [],
  isLoading: false,
  hasError: false,
  iid: null,
  active: true,
  strategies: [],
  version: LEGACY_FLAG,
});
