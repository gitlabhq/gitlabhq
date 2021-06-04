import Api from '~/api';
import createFlash from '~/flash';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import * as types from './mutation_types';

export const requestStatistics = ({ commit }) => commit(types.REQUEST_STATISTICS);

export const fetchStatistics = ({ dispatch }) => {
  dispatch('requestStatistics');

  Api.adminStatistics()
    .then(({ data }) => {
      dispatch('receiveStatisticsSuccess', convertObjectPropsToCamelCase(data, { deep: true }));
    })
    .catch((error) => dispatch('receiveStatisticsError', error));
};

export const receiveStatisticsSuccess = ({ commit }, statistics) =>
  commit(types.RECEIVE_STATISTICS_SUCCESS, statistics);

export const receiveStatisticsError = ({ commit }, error) => {
  commit(types.RECEIVE_STATISTICS_ERROR, error);
  createFlash({
    message: s__('AdminDashboard|Error loading the statistics. Please try again'),
  });
};
