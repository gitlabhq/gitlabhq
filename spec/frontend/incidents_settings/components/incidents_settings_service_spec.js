import AxiosMockAdapter from 'axios-mock-adapter';
import { createAlert } from '~/alert';
import { ERROR_MSG } from '~/incidents_settings/constants';
import IncidentsSettingsService from '~/incidents_settings/incidents_settings_service';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { refreshCurrentPage } from '~/lib/utils/url_utility';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');

describe('IncidentsSettingsService', () => {
  const settingsEndpoint = 'operations/settings';
  const webhookUpdateEndpoint = 'webhook/update';
  let mock;
  let service;

  beforeEach(() => {
    mock = new AxiosMockAdapter(axios);
    service = new IncidentsSettingsService(settingsEndpoint, webhookUpdateEndpoint);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('updateSettings', () => {
    it('should refresh the page on successful update', () => {
      mock.onPatch().reply(HTTP_STATUS_OK);

      return service.updateSettings({}).then(() => {
        expect(refreshCurrentPage).toHaveBeenCalled();
      });
    });

    it('should display an alert on update error', () => {
      mock.onPatch().reply(HTTP_STATUS_BAD_REQUEST);

      return service.updateSettings({}).then(() => {
        expect(createAlert).toHaveBeenCalledWith({
          message: expect.stringContaining(ERROR_MSG),
        });
      });
    });
  });

  describe('resetWebhookUrl', () => {
    it('should make a call for webhook update', () => {
      jest.spyOn(axios, 'post');
      mock.onPost().reply(HTTP_STATUS_OK);

      return service.resetWebhookUrl().then(() => {
        expect(axios.post).toHaveBeenCalledWith(webhookUpdateEndpoint);
      });
    });
  });
});
