import { FEATURE_FLAG_SCOPE, USER_LIST_SCOPE } from '../../constants';

export default ({ endpoint, projectId, unleashApiInstanceId, rotateInstanceIdPath }) => ({
  [FEATURE_FLAG_SCOPE]: [],
  [USER_LIST_SCOPE]: [],
  alerts: [],
  count: {},
  pageInfo: { [FEATURE_FLAG_SCOPE]: {}, [USER_LIST_SCOPE]: {} },
  isLoading: true,
  hasError: false,
  endpoint,
  rotateEndpoint: rotateInstanceIdPath,
  instanceId: unleashApiInstanceId,
  isRotating: false,
  hasRotateError: false,
  options: {},
  projectId,
});
