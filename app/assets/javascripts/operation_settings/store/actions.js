import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import createFlash from '~/flash';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import * as mutationTypes from './mutation_types';

export const setExternalDashboardUrl = ({ commit }, url) =>
  commit(mutationTypes.SET_EXTERNAL_DASHBOARD_URL, url);

export const updateExternalDashboardUrl = ({ state, dispatch }) =>
  axios
    .patch(state.operationsSettingsEndpoint, {
      project: {
        metrics_setting_attributes: {
          external_dashboard_url: state.externalDashboardUrl,
        },
      },
    })
    .then(() => dispatch('receiveExternalDashboardUpdateSuccess'))
    .catch(error => dispatch('receiveExternalDashboardUpdateError', error));

export const receiveExternalDashboardUpdateSuccess = () => {
  /**
   * The operations_controller currently handles successful requests
   * by creating a flash banner messsage to notify the user.
   */
  refreshCurrentPage();
};

export const receiveExternalDashboardUpdateError = (_, error) => {
  const { response } = error;
  const message = response.data && response.data.message ? response.data.message : '';

  createFlash(`${__('There was an error saving your changes.')} ${message}`, 'alert');
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
