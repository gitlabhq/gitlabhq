import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';
import { parseCodeclimateMetrics, doCodeClimateComparison } from './utils/codequality_comparison';

export const setPaths = ({ commit }, paths) => commit(types.SET_PATHS, paths);

export const fetchReports = ({ state, dispatch, commit }) => {
  commit(types.REQUEST_REPORTS);

  if (!state.basePath) {
    return dispatch('receiveReportsError');
  }
  return Promise.all([axios.get(state.headPath), axios.get(state.basePath)])
    .then(results =>
      doCodeClimateComparison(
        parseCodeclimateMetrics(results[0].data, state.headBlobPath),
        parseCodeclimateMetrics(results[1].data, state.baseBlobPath),
      ),
    )
    .then(data => dispatch('receiveReportsSuccess', data))
    .catch(() => dispatch('receiveReportsError'));
};

export const receiveReportsSuccess = ({ commit }, data) => {
  commit(types.RECEIVE_REPORTS_SUCCESS, data);
};

export const receiveReportsError = ({ commit }) => {
  commit(types.RECEIVE_REPORTS_ERROR);
};
