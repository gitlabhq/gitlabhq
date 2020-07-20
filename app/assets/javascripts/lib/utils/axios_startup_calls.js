import { isEmpty } from 'lodash';
import { mergeUrlParams } from './url_utility';

// We should probably not couple this utility to `gon.gitlab_url`
// Also, this would replace occurrences that aren't at the beginning of the string
const removeGitLabUrl = url => url.replace(gon.gitlab_url, '');

const getFullUrl = req => {
  const url = removeGitLabUrl(req.url);
  return mergeUrlParams(req.params || {}, url);
};

const setupAxiosStartupCalls = axios => {
  const { startup_calls: startupCalls } = window.gl || {};

  if (!startupCalls || isEmpty(startupCalls)) {
    return;
  }

  // TODO: To save performance of future axios calls, we can
  // remove this interceptor once the "startupCalls" have been loaded
  axios.interceptors.request.use(req => {
    const fullUrl = getFullUrl(req);

    const existing = startupCalls[fullUrl];

    if (existing) {
      // eslint-disable-next-line no-param-reassign
      req.adapter = () =>
        existing.fetchCall.then(res => {
          const fetchHeaders = {};
          res.headers.forEach((val, key) => {
            fetchHeaders[key] = val;
          });

          // eslint-disable-next-line promise/no-nesting
          return res.json().then(data => ({
            data,
            status: res.status,
            statusText: res.statusText,
            headers: fetchHeaders,
            config: req,
            request: req,
          }));
        });
    }

    return req;
  });
};

export default setupAxiosStartupCalls;
