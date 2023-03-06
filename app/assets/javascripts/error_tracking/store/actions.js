import { createAlert } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import service from '../services';
import * as types from './mutation_types';

export const setStatus = ({ commit }, status) => {
  commit(types.SET_ERROR_STATUS, status.toLowerCase());
};

export const updateStatus = ({ commit }, { endpoint, redirectUrl, status }) =>
  service
    .updateErrorStatus(endpoint, status)
    .then((resp) => {
      commit(types.SET_ERROR_STATUS, status);
      if (redirectUrl) visitUrl(redirectUrl);

      return resp.data.result;
    })
    .catch(() =>
      createAlert({
        message: __('Failed to update issue status'),
      }),
    );

export const updateResolveStatus = ({ commit, dispatch }, params) => {
  commit(types.SET_UPDATING_RESOLVE_STATUS, true);

  return dispatch('updateStatus', params).finally(() => {
    commit(types.SET_UPDATING_RESOLVE_STATUS, false);
  });
};

export const updateIgnoreStatus = ({ commit, dispatch }, params) => {
  commit(types.SET_UPDATING_IGNORE_STATUS, true);

  return dispatch('updateStatus', params).finally(() => {
    commit(types.SET_UPDATING_IGNORE_STATUS, false);
  });
};
