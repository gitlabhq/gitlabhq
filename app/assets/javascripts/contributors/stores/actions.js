import flash from '~/flash';
import { __ } from '~/locale';
import service from '../services/contributors_service';
import * as types from './mutation_types';

export const fetchChartData = ({ commit }, endpoint) => {
  commit(types.SET_LOADING_STATE, true);

  return service
    .fetchChartData(endpoint)
    .then(res => res.data)
    .then(data => {
      commit(types.SET_CHART_DATA, data);
      commit(types.SET_LOADING_STATE, false);
    })
    .catch(() => flash(__('An error occurred while loading chart data')));
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
