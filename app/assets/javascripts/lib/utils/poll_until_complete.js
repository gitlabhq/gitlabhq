import axios from '~/lib/utils/axios_utils';
import Poll from './poll';
import httpStatusCodes from './http_status';

/**
 * Polls an endpoint until it returns either a 200 OK or a error status.
 * The Poll-Interval header in the responses are used to determine how
 * frequently to poll.
 *
 * Once a 200 OK is received, the promise resolves with that response. If an
 * error status is received, the promise rejects with the error.
 *
 * @param {string} url - The URL to poll.
 * @param {Object} [config] - The config to provide to axios.get().
 * @returns {Promise}
 */
export default (url, config = {}) =>
  new Promise((resolve, reject) => {
    const eTagPoll = new Poll({
      resource: {
        axiosGet(data) {
          return axios.get(data.url, {
            headers: {
              'Content-Type': 'application/json',
            },
            ...data.config,
          });
        },
      },
      data: { url, config },
      method: 'axiosGet',
      successCallback: response => {
        if (response.status === httpStatusCodes.OK) {
          resolve(response);
          eTagPoll.stop();
        }
      },
      errorCallback: reject,
    });

    eTagPoll.makeRequest();
  });
