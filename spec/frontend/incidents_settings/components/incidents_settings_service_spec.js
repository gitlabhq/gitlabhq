import AxiosMockAdapter from 'axios-mock-adapter';
import createFlash from '~/flash';
import { ERROR_MSG } from '~/incidents_settings/constants';
import IncidentsSettingsService from '~/incidents_settings/incidents_settings_service';
import axios from '~/lib/utils/axios_utils';
import httpStatusCodes from '~/lib/utils/http_status';
import { refreshCurrentPage } from '~/lib/utils/url_utility';

jest.mock('~/flash');
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
      mock.onPatch().reply(httpStatusCodes.OK);

      return service.updateSettings({}).then(() => {
        expect(refreshCurrentPage).toHaveBeenCalled();
      });
    });

    it('should display a flash message on update error', () => {
      mock.onPatch().reply(httpStatusCodes.BAD_REQUEST);

      return service.updateSettings({}).then(() => {
        expect(createFlash).toHaveBeenCalledWith({
          message: expect.stringContaining(ERROR_MSG),
        });
      });
    });
  });

  describe('resetWebhookUrl', () => {
    it('should make a call for webhook update', () => {
      jest.spyOn(axios, 'post');
      mock.onPost().reply(httpStatusCodes.OK);

      return service.resetWebhookUrl().then(() => {
        expect(axios.post).toHaveBeenCalledWith(webhookUpdateEndpoint);
      });
    });
  });
});
