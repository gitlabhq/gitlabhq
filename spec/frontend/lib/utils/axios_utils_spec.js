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

      it('adds X-GitLab-Organization-ID header', async () => {
        await axios.get('/ok');

        expect(mock.history.get[0].headers['X-GitLab-Organization-ID']).toBe(
          currentOrganization.id,
        );
      });
    });

    describe('when gon.current_organization is not available', () => {
      beforeEach(setup);

      it('does not add X-GitLab-Organization-ID header', async () => {
        await axios.get('/ok');

        expect(mock.history.get[0].headers['X-GitLab-Organization-ID']).toBe(undefined);
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
