import { isEmpty } from 'lodash-es';
import { mergeUrlParams } from './url_utility';

// We should probably not couple this utility to `gon.gitlab_url`
// Also, this would replace occurrences that aren't at the beginning of the string
const removeGitLabUrl = (url) => url.replace(gon.gitlab_url, '');

const getFullUrl = (req) => {
  const url = removeGitLabUrl(req.url);
  return mergeUrlParams(req.params || {}, url, { sort: true });
};

const handleStartupCall = async ({ fetchCall }, req) => {
  const res = await fetchCall;
  if (!res.ok) {
    throw new Error(res.statusText);
  }

  const fetchHeaders = {};
  res.headers.forEach((val, key) => {
    fetchHeaders[key] = val;
  });

  const data = await res.clone().json();

  Object.assign(req, {
    adapter: () =>
      Promise.resolve({
        data,
        status: res.status,
        statusText: res.statusText,
        headers: fetchHeaders,
        config: req,
        request: req,
      }),
  });
};

const setupAxiosStartupCalls = (axios) => {
  const { startup_calls: startupCalls } = window.gl || {};

  if (!startupCalls || isEmpty(startupCalls)) {
    return;
  }

  const interceptor = axios.interceptors.request.use(async (req) => {
    const fullUrl = getFullUrl(req);

    const startupCall = startupCalls[fullUrl];

    if (!startupCall?.fetchCall) {
      return req;
    }

    try {
      await handleStartupCall(startupCall, req);
    } catch (e) {
      // eslint-disable-next-line no-console
      console.warn(`[gitlab] Something went wrong with the startup call for "${fullUrl}"`, e);
    }

    // A startup response may be replayed once per page. The Vue 2 and Vue 3
    // realms each load their own axios_utils and install this interceptor on
    // the shared axios instance, so the consumed state lives on gl.startup_calls.
    delete startupCalls[fullUrl];

    if (isEmpty(startupCalls)) {
      axios.interceptors.request.eject(interceptor);
    }

    return req;
  });
};

export default setupAxiosStartupCalls;
