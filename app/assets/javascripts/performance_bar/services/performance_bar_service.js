import Vue from 'vue';
import _ from 'underscore';
import axios from '../../lib/utils/axios_utils';

let vueResourceInterceptor;

export default class PerformanceBarService {
  static fetchRequestDetails(peekUrl, requestId) {
    return axios.get(peekUrl, { params: { request_id: requestId } });
  }

  static registerInterceptor(peekUrl, callback) {
    vueResourceInterceptor = (request, next) => {
      next(response => {
        const requestId = response.headers['x-request-id'];
        const requestUrl = response.url;

        if (requestUrl !== peekUrl && requestId) {
          callback(requestId, requestUrl);
        }
      });
    };

    Vue.http.interceptors.push(vueResourceInterceptor);

    return axios.interceptors.response.use(response => {
      const requestId = response.headers['x-request-id'];
      const requestUrl = response.config.url;

      if (requestUrl !== peekUrl && requestId) {
        callback(requestId, requestUrl);
      }

      return response;
    });
  }

  static removeInterceptor(interceptor) {
    axios.interceptors.response.eject(interceptor);
    Vue.http.interceptors = _.without(
      Vue.http.interceptors,
      vueResourceInterceptor,
    );
  }
}
