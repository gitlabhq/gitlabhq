import pollUntilComplete from '~/lib/utils/poll_until_complete';
import { STATUS_NOT_FOUND } from '../../constants';
import * as types from './mutation_types';
import { parseCodeclimateMetrics } from './utils/codequality_parser';

export const setPaths = ({ commit }, paths) => commit(types.SET_PATHS, paths);

export const fetchReports = ({ state, dispatch, commit }) => {
  commit(types.REQUEST_REPORTS);

  return pollUntilComplete(state.reportsPath)
    .then(({ data }) => {
      if (data.status === STATUS_NOT_FOUND) {
        return dispatch('receiveReportsError', data);
      }
      return dispatch('receiveReportsSuccess', {
        newIssues: parseCodeclimateMetrics(data.new_errors, state.headBlobPath),
        resolvedIssues: parseCodeclimateMetrics(data.resolved_errors, state.baseBlobPath),
      });
    })
    .catch((error) => dispatch('receiveReportsError', error));
};

export const receiveReportsSuccess = ({ commit }, data) => {
  commit(types.RECEIVE_REPORTS_SUCCESS, data);
};

export const receiveReportsError = ({ commit }, error) => {
  commit(types.RECEIVE_REPORTS_ERROR, error);
};
