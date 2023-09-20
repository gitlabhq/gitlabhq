import MockAdapter from 'axios-mock-adapter';
import * as applicationSettingsApi from '~/api/application_settings_api';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('~/api/application_settings_api.js', () => {
  const MOCK_SETTINGS_RES = { test_setting: 'foo' };
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    window.gon = { api_version: 'v7' };
  });

  afterEach(() => {
    mock.restore();
  });

  describe('getApplicationSettings', () => {
    it('fetches application settings', () => {
      const expectedUrl = '/api/v7/application/settings';
      jest.spyOn(axios, 'get');
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, MOCK_SETTINGS_RES);

      return applicationSettingsApi.getApplicationSettings().then(({ data }) => {
        expect(data).toEqual(MOCK_SETTINGS_RES);
        expect(axios.get).toHaveBeenCalledWith(expectedUrl);
      });
    });
  });

  describe('updateApplicationSettings', () => {
    it('updates application settings', () => {
      const expectedUrl = '/api/v7/application/settings';
      const MOCK_REQ = { another_setting: 'bar' };
      jest.spyOn(axios, 'put');
      mock.onPut(expectedUrl).reply(HTTP_STATUS_OK, MOCK_SETTINGS_RES);

      return applicationSettingsApi.updateApplicationSettings(MOCK_REQ).then(({ data }) => {
        expect(data).toEqual(MOCK_SETTINGS_RES);
        expect(axios.put).toHaveBeenCalledWith(expectedUrl, MOCK_REQ);
      });
    });
  });
});
