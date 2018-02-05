import axios from 'axios';
import csrf from './csrf';

axios.defaults.headers.common[csrf.headerKey] = csrf.token;
// Used by Rails to check if it is a valid XHR request
axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';

// Maintain a global counter for active requests
// see: spec/support/wait_for_requests.rb
axios.interceptors.request.use((config) => {
  window.activeVueResources = window.activeVueResources || 0;
  window.activeVueResources += 1;

  return config;
});

// Remove the global counter
axios.interceptors.response.use((config) => {
  window.activeVueResources -= 1;

  return config;
}, (e) => {
  window.activeVueResources -= 1;

  return Promise.reject(e);
});

export default axios;

/**
 * @return The adapter that axios uses for dispatching requests. This may be overwritten in tests.
 *
 * @see https://github.com/axios/axios/tree/master/lib/adapters
 * @see https://github.com/ctimmerm/axios-mock-adapter/blob/v1.12.0/src/index.js#L39
 */
export const getDefaultAdapter = () => axios.defaults.adapter;
