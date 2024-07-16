import { parseBoolean } from '~/lib/utils/common_utils';
import axios from '~/lib/utils/axios_utils';

export default class PerformanceBarService {
  static interceptor = null;

  static fetchRequestDetails(peekUrl, requestId) {
    return axios.get(peekUrl, { params: { request_id: requestId } });
  }

  static registerInterceptor(peekUrl, callback) {
    PerformanceBarService.interceptor = (response) => {
      const [fireCallback, requestId, requestUrl, requestParams, operationName, methodVerb] =
        PerformanceBarService.callbackParams(response, peekUrl);

      if (fireCallback) {
        callback(requestId, requestUrl, operationName, requestParams, methodVerb);
      }

      return response;
    };

    return axios.interceptors.response.use(PerformanceBarService.interceptor);
  }

  static removeInterceptor() {
    axios.interceptors.response.eject(PerformanceBarService.interceptor);
    PerformanceBarService.interceptor = null;
  }

  static callbackParams(response, peekUrl) {
    const requestId = response.headers && response.headers['x-request-id'];
    const requestUrl = response.config?.url;
    const requestParams = response.config?.params;
    const methodVerb = response.config?.method;

    const cachedResponse =
      response.headers && parseBoolean(response.headers['x-gitlab-from-cache']);
    const fireCallback = requestUrl !== peekUrl && Boolean(requestId) && !cachedResponse;
    const operationName = response.config?.operationName;

    return [fireCallback, requestId, requestUrl, requestParams, operationName, methodVerb];
  }
}
