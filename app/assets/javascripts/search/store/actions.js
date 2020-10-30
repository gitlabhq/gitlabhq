import Api from '~/api';
import createFlash from '~/flash';
import { __ } from '~/locale';
import * as types from './mutation_types';

export const fetchGroups = ({ commit }, search) => {
  commit(types.REQUEST_GROUPS);
  Api.groups(search)
    .then(data => {
      commit(types.RECEIVE_GROUPS_SUCCESS, data);
    })
    .catch(() => {
      createFlash({ message: __('There was a problem fetching groups.') });
      commit(types.RECEIVE_GROUPS_ERROR);
    });
};
