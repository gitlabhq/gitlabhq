import { FEATURE_FLAG_SCOPE, USER_LIST_SCOPE } from '../../../constants';

export default () => ({
  [FEATURE_FLAG_SCOPE]: [],
  [USER_LIST_SCOPE]: [],
  alerts: [],
  count: {},
  pageInfo: { [FEATURE_FLAG_SCOPE]: {}, [USER_LIST_SCOPE]: {} },
  isLoading: true,
  hasError: false,
  endpoint: null,
  rotateEndpoint: null,
  instanceId: '',
  isRotating: false,
  hasRotateError: false,
  options: {},
  projectId: '',
});
