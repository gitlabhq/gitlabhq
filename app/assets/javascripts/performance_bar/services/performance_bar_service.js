import axios from '../../lib/utils/axios_utils';

export default class PerformanceBarService {
  static fetchRequestDetails(peekUrl, requestId) {
    return axios.get(peekUrl, { params: { request_id: requestId } });
  }

  static registerInterceptor(peekUrl, callback) {
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
  }
}
