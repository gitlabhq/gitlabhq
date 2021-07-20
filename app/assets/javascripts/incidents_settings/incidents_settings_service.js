import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import { ERROR_MSG } from './constants';

export default class IncidentsSettingsService {
  constructor(settingsEndpoint, webhookUpdateEndpoint) {
    this.settingsEndpoint = settingsEndpoint;
    this.webhookUpdateEndpoint = webhookUpdateEndpoint;
  }

  updateSettings(data) {
    return axios
      .patch(this.settingsEndpoint, {
        project: {
          incident_management_setting_attributes: data,
        },
      })
      .then(() => {
        refreshCurrentPage();
      })
      .catch(({ response }) => {
        const message = response?.data?.message || '';

        createFlash({
          message: `${ERROR_MSG} ${message}`,
        });
      });
  }

  resetWebhookUrl() {
    return axios.post(this.webhookUpdateEndpoint);
  }
}
