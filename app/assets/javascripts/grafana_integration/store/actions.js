import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import * as mutationTypes from './mutation_types';

export const setGrafanaUrl = ({ commit }, url) => commit(mutationTypes.SET_GRAFANA_URL, url);

export const setGrafanaToken = ({ commit }, token) =>
  commit(mutationTypes.SET_GRAFANA_TOKEN, token);

export const setGrafanaEnabled = ({ commit }, enabled) =>
  commit(mutationTypes.SET_GRAFANA_ENABLED, enabled);

export const updateGrafanaIntegration = ({ state, dispatch }) =>
  axios
    .patch(state.operationsSettingsEndpoint, {
      project: {
        grafana_integration_attributes: {
          grafana_url: state.grafanaUrl,
          token: state.grafanaToken,
          enabled: state.grafanaEnabled,
        },
      },
    })
    .then(() => dispatch('receiveGrafanaIntegrationUpdateSuccess'))
    .catch((error) => dispatch('receiveGrafanaIntegrationUpdateError', error));

export const receiveGrafanaIntegrationUpdateSuccess = () => {
  /**
   * The operations_controller currently handles successful requests
   * by creating a flash banner messsage to notify the user.
   */
  refreshCurrentPage();
};

export const receiveGrafanaIntegrationUpdateError = (_, error) => {
  const { response } = error;
  const message = response.data && response.data.message ? response.data.message : '';

  createFlash({
    message: `${__('There was an error saving your changes.')} ${message}`,
  });
};
