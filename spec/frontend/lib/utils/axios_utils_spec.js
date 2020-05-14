/* eslint-disable promise/catch-or-return */

import AxiosMockAdapter from 'axios-mock-adapter';

import axios from '~/lib/utils/axios_utils';

describe('axios_utils', () => {
  let mock;

  beforeEach(() => {
    mock = new AxiosMockAdapter(axios);
    mock.onAny('/ok').reply(200);
    mock.onAny('/err').reply(500);
    // eslint-disable-next-line jest/no-standalone-expect
    expect(axios.countActiveRequests()).toBe(0);
  });

  afterEach(() => axios.waitForAll().finally(() => mock.restore()));

  describe('waitForAll', () => {
    it('resolves if there are no requests', () => axios.waitForAll());

    it('waits for all requests to finish', () => {
      const handler = jest.fn();
      axios.get('/ok').then(handler);
      axios.get('/err').catch(handler);

      return axios.waitForAll().finally(() => {
        expect(handler).toHaveBeenCalledTimes(2);
        expect(handler.mock.calls[0][0].status).toBe(200);
        expect(handler.mock.calls[1][0].response.status).toBe(500);
      });
    });
  });

  describe('waitFor', () => {
    it('waits for requests on a specific URL', () => {
      const handler = jest.fn();
      axios.get('/ok').finally(handler);
      axios.waitFor('/err').finally(() => {
        throw new Error('waitFor on /err should not be called');
      });
      return axios.waitFor('/ok');
    });
  });
});
