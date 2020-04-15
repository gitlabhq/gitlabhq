import * as types from './mutation_types';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { __ } from '~/locale';

export default {
  setInitialData({ commit }, data) {
    commit(types.SET_INITIAL_DATA, data);
  },
  receiveAuthorsSuccess({ commit }, authors) {
    commit(types.COMMITS_AUTHORS, authors);
  },
  receiveAuthorsError() {
    createFlash(__('An error occurred fetching the project authors.'));
  },
  fetchAuthors({ dispatch, state }, author = null) {
    const { projectId } = state;
    const path = '/autocomplete/users.json';

    return axios
      .get(path, {
        params: {
          project_id: projectId,
          active: true,
          search: author,
        },
      })
      .then(({ data }) => dispatch('receiveAuthorsSuccess', data))
      .catch(() => dispatch('receiveAuthorsError'));
  },
};
