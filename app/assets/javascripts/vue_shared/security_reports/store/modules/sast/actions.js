import { REPORT_TYPE_SAST } from '~/vue_shared/security_reports/constants';
import { fetchDiffData } from '../../utils';
import * as types from './mutation_types';

export const setDiffEndpoint = ({ commit }, path) => commit(types.SET_DIFF_ENDPOINT, path);

export const requestDiff = ({ commit }) => commit(types.REQUEST_DIFF);

export const receiveDiffSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_DIFF_SUCCESS, response);

export const receiveDiffError = ({ commit }, response) =>
  commit(types.RECEIVE_DIFF_ERROR, response);

export const fetchDiff = ({ state, rootState, dispatch }) => {
  dispatch('requestDiff');

  return fetchDiffData(rootState, state.paths.diffEndpoint, REPORT_TYPE_SAST)
    .then((data) => {
      dispatch('receiveDiffSuccess', data);
      return data;
    })
    .catch(() => {
      dispatch('receiveDiffError');
    });
};
