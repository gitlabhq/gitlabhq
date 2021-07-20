import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import * as mutationTypes from './mutation_types';

export const setExternalDashboardUrl = ({ commit }, url) =>
  commit(mutationTypes.SET_EXTERNAL_DASHBOARD_URL, url);

export const setDashboardTimezone = ({ commit }, selected) =>
  commit(mutationTypes.SET_DASHBOARD_TIMEZONE, selected);

export const saveChanges = ({ state, dispatch }) =>
  axios
    .patch(state.operationsSettingsEndpoint, {
      project: {
        metrics_setting_attributes: {
          dashboard_timezone: state.dashboardTimezone.selected,
          external_dashboard_url: state.externalDashboard.url,
        },
      },
    })
    .then(() => dispatch('receiveSaveChangesSuccess'))
    .catch((error) => dispatch('receiveSaveChangesError', error));

export const receiveSaveChangesSuccess = () => {
  /**
   * The operations_controller currently handles successful requests
   * by creating a flash banner messsage to notify the user.
   */
  refreshCurrentPage();
};

export const receiveSaveChangesError = (_, error) => {
  const { response = {} } = error;
  const message = response.data && response.data.message ? response.data.message : '';

  createFlash({
    message: `${__('There was an error saving your changes.')} ${message}`,
  });
};
