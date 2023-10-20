import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { ACTIVE_AND_BLOCKED_USER_STATES } from '~/users_select/constants';
import * as types from './mutation_types';

export default {
  setInitialData({ commit }, data) {
    commit(types.SET_INITIAL_DATA, data);
  },
  receiveAuthorsSuccess({ commit }, authors) {
    commit(types.COMMITS_AUTHORS, authors);
  },
  receiveAuthorsError() {
    createAlert({
      message: __('An error occurred fetching the project authors.'),
    });
  },
  fetchAuthors({ dispatch, state }, author = null) {
    const { projectId } = state;
    return axios
      .get(joinPaths(gon.relative_url_root || '', '/-/autocomplete/users.json'), {
        params: {
          project_id: projectId,
          states: ACTIVE_AND_BLOCKED_USER_STATES,
          search: author,
        },
      })
      .then(({ data }) => dispatch('receiveAuthorsSuccess', data))
      .catch((error) => {
        Sentry.captureException(error);
        dispatch('receiveAuthorsError');
      });
  },
};
