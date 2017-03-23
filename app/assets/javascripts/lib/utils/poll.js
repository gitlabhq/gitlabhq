import httpStatusCodes from './http_status';

/**
 * Polling utility for handling realtime updates.
 * Service for vue resouce and method need to be provided as props
 *
 * @example
 * new poll({
 *   resource: resource,
 *   method: 'name',
 *   data: {page: 1, scope: 'all'},
 *   successCallback: () => {},
 *   errorCallback: () => {},
 * }).makeRequest();
 *
 * this.service = new BoardsService(endpoint);
 * new poll({
 *   resource: this.service,
 *   method: 'get',
 *   data: {page: 1, scope: 'all'},
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
export default class Poll {
  constructor(options = {}) {
    this.options = options;
    this.options.data = options.data || {};

    this.intervalHeader = 'POLL-INTERVAL';
    this.timeoutID = null;
    this.canPoll = true;
  }

  checkConditions(response) {
    const headers = gl.utils.normalizeHeaders(response.headers);
    const pollInterval = headers[this.intervalHeader];

    if (pollInterval > 0 && response.status === httpStatusCodes.OK && this.canPoll) {
      this.timeoutID = setTimeout(() => {
        this.makeRequest();
      }, pollInterval);
    }

    this.options.successCallback(response);
  }

  makeRequest() {
    const { resource, method, data, errorCallback } = this.options;

    return resource[method](data)
    .then(response => this.checkConditions(response))
    .catch(error => errorCallback(error));
  }

  /**
   * Stops the polling recursive chain
   * and guarantees if the timeout is already running it won't make another request by
   * cancelling the previously established timeout.
   */
  stop() {
    this.canPoll = false;
    clearTimeout(this.timeoutID);
  }
}
