import Api from '~/api';
import { __ } from '~/locale';
import * as types from './mutation_types';

export const requestBranches = ({ commit }) => commit(types.REQUEST_BRANCHES);
export const receiveBranchesError = ({ commit, dispatch }, { search }) => {
  dispatch(
    'setErrorMessage',
    {
      text: __('Error loading branches.'),
      action: (payload) =>
        dispatch('fetchBranches', payload).then(() =>
          dispatch('setErrorMessage', null, { root: true }),
        ),
      actionText: __('Please try again'),
      actionPayload: { search },
    },
    { root: true },
  );
  commit(types.RECEIVE_BRANCHES_ERROR);
};
export const receiveBranchesSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_BRANCHES_SUCCESS, data);

export const fetchBranches = ({ dispatch, rootGetters }, { search = '' }) => {
  dispatch('requestBranches');
  dispatch('resetBranches');

  return Api.branches(rootGetters.currentProject.id, search, { sort: 'updated_desc' })
    .then(({ data }) => dispatch('receiveBranchesSuccess', data))
    .catch(() => dispatch('receiveBranchesError', { search }));
};

export const resetBranches = ({ commit }) => commit(types.RESET_BRANCHES);
