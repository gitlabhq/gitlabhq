/* eslint-disable promise/catch-or-return */

import AxiosMockAdapter from 'axios-mock-adapter';

import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { defaultOrganization as currentOrganization } from 'jest/organizations/mock_data';

describe('axios_utils', () => {
  let axios;
  let mock;

  const setup = async () => {
    axios = (await import('~/lib/utils/axios_utils')).default;

    mock = new AxiosMockAdapter(axios);
    mock.onAny('/ok').reply(HTTP_STATUS_OK);
    mock.onAny('/err').reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
    expect(axios.countActiveRequests()).toBe(0);
  };

  beforeEach(() => {
    jest.resetModules();
  });

  afterEach(() => {
    axios.waitForAll().finally(() => mock.restore());
    axios = null;
    window.gon = {};
  });

  describe('headers', () => {
    describe('when gon.current_organization is available', () => {
      beforeEach(async () => {
        window.gon = {
          current_organization: currentOrganization,
        };

        await setup();
      });

      it('adds X-GitLab-Organization-ID header to same-origin requests', async () => {
        await axios.get('/ok');

        expect(mock.history.get[0].headers['X-GitLab-Organization-ID']).toBe(
          currentOrganization.id,
        );
      });

      it('does not add X-GitLab-Organization-ID header to cross-origin requests', async () => {
        mock.onAny('https://other.example.com/ok').reply(HTTP_STATUS_OK);

        await axios.get('https://other.example.com/ok');

        expect(mock.history.get[0].headers['X-GitLab-Organization-ID']).toBe(undefined);
      });

      it('does not add X-GitLab-Organization-ID header when baseURL is cross-origin', async () => {
        mock.onAny('https://other.example.com/ok').reply(HTTP_STATUS_OK);

        await axios.get('/ok', { baseURL: 'https://other.example.com' });

        expect(mock.history.get[0].headers['X-GitLab-Organization-ID']).toBe(undefined);
      });
    });

    describe('when gon.current_organization is not available', () => {
      beforeEach(setup);

      it('does not add X-GitLab-Organization-ID header', async () => {
        await axios.get('/ok');

        expect(mock.history.get[0].headers['X-GitLab-Organization-ID']).toBe(undefined);
      });
    });

    describe('client identity', () => {
      beforeEach(async () => {
        await setup();
        mock.onAny('https://other.example.com/ok').reply(HTTP_STATUS_OK);
      });

      it('adds the client type header to same-origin requests', async () => {
        await axios.get('/ok');

        expect(mock.history.get[0].headers['X-GitLab-Client-Type']).toBe('browser');
      });

      it('does not add the client type header to cross-origin requests', async () => {
        await axios.get('https://other.example.com/ok');

        expect(mock.history.get[0].headers['X-GitLab-Client-Type']).toBe(undefined);
      });
    });
  });

  describe('background request header', () => {
    let userActivity;

    const getBackgroundHeader = async (url, config) => {
      mock.onGet(url).reply(HTTP_STATUS_OK);
      await axios.get(url, config);

      return mock.history.get[0].headers[userActivity.BACKGROUND_REQUEST_HEADER];
    };

    beforeEach(async () => {
      await setup();
      userActivity = await import('~/lib/utils/user_activity');
    });

    it('is not added while the user is active', async () => {
      userActivity.setLastActivityAtForTestsOnly(performance.now());

      expect(await getBackgroundHeader('/ok')).toBeUndefined();
    });

    describe('when the user is idle', () => {
      beforeEach(() => {
        userActivity.setLastActivityAtForTestsOnly(
          performance.now() - userActivity.IDLE_THRESHOLD_MS,
        );
      });

      it('is added to same-origin requests', async () => {
        expect(await getBackgroundHeader('/ok')).toBe('1');
      });

      it('is not added to cross-origin requests', async () => {
        expect(await getBackgroundHeader('https://other.example.com/ok')).toBeUndefined();
      });

      it('is not added when baseURL is cross-origin', async () => {
        mock.onGet('https://other.example.com/ok').reply(HTTP_STATUS_OK);

        expect(
          await getBackgroundHeader('/ok', { baseURL: 'https://other.example.com' }),
        ).toBeUndefined();
      });
    });
  });

  describe('waitForAll', () => {
    beforeEach(setup);

    it('resolves if there are no requests', () => axios.waitForAll());

    it('waits for all requests to finish', () => {
      const handler = jest.fn();
      axios.get('/ok').then(handler);
      axios.get('/err').catch(handler);

      return axios.waitForAll().finally(() => {
        expect(handler).toHaveBeenCalledTimes(2);
        expect(handler.mock.calls[0][0].status).toBe(HTTP_STATUS_OK);
        expect(handler.mock.calls[1][0].response.status).toBe(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      });
    });
  });

  describe('waitFor', () => {
    beforeEach(setup);

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
