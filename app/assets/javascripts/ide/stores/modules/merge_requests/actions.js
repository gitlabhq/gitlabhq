import { __ } from '../../../../locale';
import Api from '../../../../api';
import flash from '../../../../flash';
import * as types from './mutation_types';

export const requestMergeRequests = ({ commit }) => commit(types.REQUEST_MERGE_REQUESTS);
export const receiveMergeRequestsError = ({ commit }) => {
  flash(__('Error loading merge requests.'));
  commit(types.RECEIVE_MERGE_REQUESTS_ERROR);
};
export const receiveMergeRequestsSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_MERGE_REQUESTS_SUCCESS, data);

export const fetchMergeRequests = ({ dispatch, state }) => {
  dispatch('requestMergeRequests');

  Api.mergeRequests({ scope: state.scope, view: 'simple' })
    .then(({ data }) => {
      dispatch('receiveMergeRequestsSuccess', data);
    })
    .catch(() => dispatch('receiveMergeRequestsError'));
};

export default () => {};
