import { __ } from '../../../../locale';
import Api from '../../../../api';
import flash from '../../../../flash';
import { scopes } from './constants';
import * as types from './mutation_types';

export const requestMergeRequests = ({ commit }, type) =>
  commit(types.REQUEST_MERGE_REQUESTS, type);
export const receiveMergeRequestsError = ({ commit }, type) => {
  flash(__('Error loading merge requests.'));
  commit(types.RECEIVE_MERGE_REQUESTS_ERROR, type);
};
export const receiveMergeRequestsSuccess = ({ commit }, { type, data }) =>
  commit(types.RECEIVE_MERGE_REQUESTS_SUCCESS, { type, data });

export const fetchMergeRequests = ({ dispatch, state: { state } }, { type, search = '' }) => {
  const scope = scopes[type];
  dispatch('requestMergeRequests', type);
  dispatch('resetMergeRequests', type);

  Api.mergeRequests({ scope, state, search })
    .then(({ data }) => dispatch('receiveMergeRequestsSuccess', { type, data }))
    .catch(() => dispatch('receiveMergeRequestsError', type));
};

export const resetMergeRequests = ({ commit }, type) => commit(types.RESET_MERGE_REQUESTS, type);

export default () => {};
