import EventEmitter from 'events';
// eslint-disable-next-line no-restricted-syntax
import { setImmediate } from 'timers';

const axios = jest.requireActual('~/lib/utils/axios_utils').default;

axios.isMock = true;

// Fail tests for unmocked requests
axios.defaults.adapter = (config) => {
  const message =
    `Unexpected unmocked request: ${JSON.stringify(config, null, 2)}\n` +
    'Consider using the `axios-mock-adapter` module in tests.';
  const error = new Error(message);
  error.config = config;
  global.fail(error);
  throw error;
};

// Count active requests and provide a way to wait for them
let activeRequests = 0;
const events = new EventEmitter();
const onRequest = () => {
  activeRequests += 1;
};

// Use setImmediate to alloow the response interceptor to finish
const onResponse = (config) => {
  activeRequests -= 1;
  // eslint-disable-next-line no-restricted-syntax
  setImmediate(() => {
    events.emit('response', config);
  });
};

const subscribeToResponse = (predicate = () => true) =>
  new Promise((resolve) => {
    const listener = (config = {}) => {
      if (predicate(config)) {
        events.off('response', listener);
        resolve(config);
      }
    };

    events.on('response', listener);

    // If a request has been made synchronously, setImmediate waits for it to be
    // processed and the counter incremented.
    // eslint-disable-next-line no-restricted-syntax
    setImmediate(listener);
  });

/**
 * Registers a callback function to be run after a request to the given URL finishes.
 */
axios.waitFor = (url) => subscribeToResponse(({ url: configUrl }) => configUrl === url);

/**
 * Registers a callback function to be run after all requests have finished. If there are no requests waiting, the callback is executed immediately.
 */
axios.waitForAll = () => subscribeToResponse(() => activeRequests === 0);

axios.countActiveRequests = () => activeRequests;

axios.interceptors.request.use((config) => {
  onRequest();
  return config;
});

// Remove the global counter
axios.interceptors.response.use(
  (response) => {
    onResponse(response.config);
    return response;
  },
  (err) => {
    onResponse(err.config);
    return Promise.reject(err);
  },
);

export default axios;
