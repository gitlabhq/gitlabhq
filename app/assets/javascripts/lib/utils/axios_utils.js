// This is the only file allowed to import directly from the package.
// eslint-disable-next-line no-restricted-imports
import axios from 'axios';
import { registerCaptchaModalInterceptor } from '~/captcha/captcha_modal_axios_interceptor';
import setupAxiosStartupCalls from './axios_startup_calls';
import csrf from './csrf';
import { isNavigatingAway } from './is_navigating_away';
import suppressAjaxErrorsDuringNavigation from './suppress_ajax_errors_during_navigation';

axios.defaults.headers.common[csrf.headerKey] = csrf.token;
// Used by Rails to check if it is a valid XHR request
axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';

if (gon.current_organization?.id) {
  axios.defaults.headers.common['X-GitLab-Organization-ID'] = gon.current_organization.id;
}

// Maintain a global counter for active requests
// see: spec/support/wait_for_requests.rb
axios.interceptors.request.use((config) => {
  window.pendingRequests = window.pendingRequests || 0;
  window.pendingRequests += 1;
  return config;
});

// Kept local instead of importing url_utility: many specs replace that module
// with a partial factory mock, which would turn every request into a TypeError.
const isSameOrigin = (url) => {
  if (typeof url !== 'string') return false;

  const { origin } = window.location;

  try {
    return new URL(url, origin).origin === origin;
  } catch {
    return false;
  }
};

// Attributes the request, and any job it enqueues, to the browser client for
// analytics; Rails reads the browser family from the User-Agent. Same origin
// only: a third party would have to allow this header in its CORS preflight.
axios.interceptors.request.use((config) => {
  if (!isSameOrigin(config.url)) return config;

  return {
    ...config,
    headers: {
      ...config.headers,
      'X-GitLab-Client-Type': 'browser',
    },
  };
});

setupAxiosStartupCalls(axios);

// Remove the global counter
axios.interceptors.response.use(
  (response) => {
    window.pendingRequests -= 1;
    return response;
  },
  (err) => {
    window.pendingRequests -= 1;
    return Promise.reject(err);
  },
);

// Ignore AJAX errors caused by requests
// being cancelled due to browser navigation
axios.interceptors.response.use(
  (response) => response,
  (err) => suppressAjaxErrorsDuringNavigation(err, isNavigatingAway()),
);

registerCaptchaModalInterceptor(axios);

export default axios;

/**
 * @return The adapter that axios uses for dispatching requests. This may be overwritten in tests.
 *
 * @see https://github.com/axios/axios/tree/master/lib/adapters
 * @see https://github.com/ctimmerm/axios-mock-adapter/blob/v1.12.0/src/index.js#L39
 */
export const getDefaultAdapter = () => axios.defaults.adapter;
