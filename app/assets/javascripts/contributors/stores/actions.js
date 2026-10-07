import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import service from '../services/contributors_service';
import * as types from './mutation_types';

const showChartDataErrorAlert = () =>
  createAlert({
    message: s__('ContributionAnalytics|An error occurred while loading chart data'),
  });

export const fetchChartData = ({ commit }, endpoint) => {
  commit(types.SET_LOADING_STATE, true);

  return service
    .fetchChartData(endpoint)
    .then((res) => res.data)
    .then((data) => {
      commit(types.SET_CHART_DATA, data);
      commit(types.SET_LOADING_STATE, false);
      return true;
    })
    .catch(() => {
      commit(types.SET_LOADING_STATE, false);
      showChartDataErrorAlert();

      return false;
    });
};

export const fetchChartStats = ({ commit, state }, endpoint) => {
  if (state.statsLoaded || state.statsLoading) {
    return Promise.resolve(true);
  }

  commit(types.SET_STATS_LOADING_STATE, true);

  return service
    .fetchChartData(endpoint, { with_stats: true })
    .then((res) => res.data)
    .then((data) => {
      commit(types.SET_CHART_STATS, data);
      commit(types.SET_STATS_LOADING_STATE, false);
      return true;
    })
    .catch(() => {
      commit(types.SET_STATS_LOADING_STATE, false);
      showChartDataErrorAlert();

      return false;
    });
};
