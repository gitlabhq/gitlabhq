import Vue from 'vue';
import _ from 'underscore';
import axios from '../../lib/utils/axios_utils';

let vueResourceInterceptor;

export default class PerformanceBarService {
  static fetchRequestDetails(peekUrl, requestId) {
    return axios.get(peekUrl, { params: { request_id: requestId } });
  }

  static registerInterceptor(peekUrl, callback) {
    const interceptor = response => {
      const [fireCallback, requestId, requestUrl] =
        PerformanceBarService.callbackParams(response, peekUrl);

      if (fireCallback) {
        callback(requestId, requestUrl);
      }

      return response;
    };

    vueResourceInterceptor = (request, next) => next(interceptor);

    Vue.http.interceptors.push(vueResourceInterceptor);

    return axios.interceptors.response.use(interceptor);
  }

  static removeInterceptor(interceptor) {
    axios.interceptors.response.eject(interceptor);
    Vue.http.interceptors = _.without(
      Vue.http.interceptors,
      vueResourceInterceptor,
    );
  }

  static callbackParams(response, peekUrl) {
    const requestId = response.headers && response.headers['x-request-id'];
    // Get the request URL from response.config for Axios, and response for
    // Vue Resource.
    const requestUrl = (response.config || response).url;
    const apiRequest = requestUrl && requestUrl.match(/^\/api\//);
    const cachedResponse = response.headers && response.headers['x-gitlab-from-cache'] === 'true';
    const fireCallback = requestUrl !== peekUrl && requestId && !apiRequest && !cachedResponse;

    return [fireCallback, requestId, requestUrl];
  }
}
