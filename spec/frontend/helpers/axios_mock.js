import { uniqueId } from 'underscore';
import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';

const axiosMock = new MockAdapter(axios);

const pendingRequests = {};

axios.interceptors.request.use(config => {
  const requestId = uniqueId('axios-request-id-');
  const newConfig = {
    ...config,
    requestId,
  };
  pendingRequests[requestId] = newConfig;
  return newConfig;
});

axios.interceptors.response.use(
  response => {
    const { requestId } = response.config;
    delete pendingRequests[requestId];
    return response;
  },
  error => {
    const { requestId } = error.config;
    delete pendingRequests[requestId];
    return Promise.reject(error);
  },
);

export const initializeAxios = (setupHook, teardownHook) => {
  setupHook(() => {
    axiosMock.reset();
  });

  teardownHook(() => {
    if (Object.keys(pendingRequests).length > 0) {
      throw new Error(
        `There are pending requests left:\n${JSON.stringify(
          Object.values(pendingRequests),
          null,
          2,
        )}`,
      );
    }
  });
};

export default axiosMock;
