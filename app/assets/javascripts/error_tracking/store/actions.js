import service from './../services';
import * as types from './mutation_types';
import createFlash from '~/flash';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';

export function updateStatus({ commit }, { endpoint, redirectUrl, status }) {
  const type =
    status === 'resolved' ? types.SET_UPDATING_RESOLVE_STATUS : types.SET_UPDATING_IGNORE_STATUS;
  commit(type, true);

  return service
    .updateErrorStatus(endpoint, status)
    .then(() => visitUrl(redirectUrl))
    .catch(() => createFlash(__('Failed to update issue status')))
    .finally(() => commit(type, false));
}

export default () => {};
