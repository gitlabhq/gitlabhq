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
      const requestId = response.headers['x-request-id'];
      // Get the request URL from response.config for Axios, and response for
      // Vue Resource.
      const requestUrl = (response.config || response).url;
      const cachedResponse = response.headers['x-gitlab-from-cache'] === 'true';

      if (requestUrl !== peekUrl && requestId && !cachedResponse) {
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
}
