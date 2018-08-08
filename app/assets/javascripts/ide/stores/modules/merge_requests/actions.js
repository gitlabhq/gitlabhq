import { __ } from '../../../../locale';
import Api from '../../../../api';
import { scopes } from './constants';
import * as types from './mutation_types';

export const requestMergeRequests = ({ commit }) =>
  commit(types.REQUEST_MERGE_REQUESTS);
export const receiveMergeRequestsError = ({ commit, dispatch }, { type, search }) => {
  dispatch(
    'setErrorMessage',
    {
      text: __('Error loading merge requests.'),
      action: payload =>
        dispatch('fetchMergeRequests', payload).then(() =>
          dispatch('setErrorMessage', null, { root: true }),
        ),
      actionText: __('Please try again'),
      actionPayload: { type, search },
    },
    { root: true },
  );
  commit(types.RECEIVE_MERGE_REQUESTS_ERROR);
};
export const receiveMergeRequestsSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_MERGE_REQUESTS_SUCCESS, data);

export const fetchMergeRequests = ({ dispatch, state: { state } }, { type, search = '' }) => {
  dispatch('requestMergeRequests');
  dispatch('resetMergeRequests');

  const scope = type ? scopes[type] : 'all';

  return Api.mergeRequests({ scope, state, search })
    .then(({ data }) => dispatch('receiveMergeRequestsSuccess', data))
    .catch(() => dispatch('receiveMergeRequestsError', { type, search }));
};

export const resetMergeRequests = ({ commit }) => commit(types.RESET_MERGE_REQUESTS);

export default () => {};
