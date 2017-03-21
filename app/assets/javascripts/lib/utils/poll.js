import httpStatusCodes from './http_status';

/**
 * Polling utility for handling realtime updates.
 * Service for vue resouce and method need to be provided as props
 *
 * @example
 * new poll({
 *   resource: resource,
 *   method: 'name',
 *   successCallback: () => {},
 *   errorCallback: () => {},
 * }).makeRequest();
 *
 * this.service = new BoardsService(endpoint);
 * new poll({
 *   resource: this.service,
 *   method: 'get',
 *   successCallback: () => {},
 *   errorCallback: () => {},
 * }).makeRequest();
 *
 *
 * 1. Checks for response and headers before start polling
 * 2. Interval is provided by `Poll-Interval` header.
 * 3. If `Poll-Interval` is -1, we stop polling
 * 4. If HTTP response is 200, we poll.
 * 5. If HTTP response is different from 200, we stop polling.
 *
 */
export default class poll {
  constructor(options = {}) {
    this.options = options;

    this.intervalHeader = 'POLL-INTERVAL';
  }

  checkConditions(response) {
    const headers = gl.utils.normalizeHeaders(response.headers);
    const pollInterval = headers[this.intervalHeader];

    if (pollInterval > 0 && response.status === httpStatusCodes.OK) {
      this.options.successCallback(response);
      setTimeout(() => {
        this.makeRequest()
          .then(this.checkConditions)
          .catch(error => this.options.errorCallback(error));
      }, pollInterval);
    } else {
      this.options.successCallback(response);
    }
  }

  makeRequest() {
    return this.options.resource[this.options.method]()
    .then(this.checkConditions.bind(this))
    .catch(error => this.options.errorCallback(error));
  }
}
