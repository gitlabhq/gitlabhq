import axios from '../../lib/utils/axios_utils';
import { parseBoolean } from '~/lib/utils/common_utils';

export default class PerformanceBarService {
  static fetchRequestDetails(peekUrl, requestId) {
    return axios.get(peekUrl, { params: { request_id: requestId } });
  }

  static registerInterceptor(peekUrl, callback) {
    const interceptor = response => {
      const [fireCallback, requestId, requestUrl] = PerformanceBarService.callbackParams(
        response,
        peekUrl,
      );

      if (fireCallback) {
        callback(requestId, requestUrl);
      }

      return response;
    };

    return axios.interceptors.response.use(interceptor);
  }

  static removeInterceptor(interceptor) {
    axios.interceptors.response.eject(interceptor);
  }

  static callbackParams(response, peekUrl) {
    const requestId = response.headers && response.headers['x-request-id'];
    // Get the request URL from response.config for Axios, and response for
    // Vue Resource.
    const requestUrl = (response.config || response).url;
    const apiRequest = requestUrl && requestUrl.match(/^\/api\//);
    const cachedResponse =
      response.headers && parseBoolean(response.headers['x-gitlab-from-cache']);
    const fireCallback = requestUrl !== peekUrl && requestId && !apiRequest && !cachedResponse;

    return [fireCallback, requestId, requestUrl];
  }
}
