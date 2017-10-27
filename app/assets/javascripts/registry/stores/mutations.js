import * as types from './mutation_types';
import { parseIntPagination, normalizeHeaders } from '../../lib/utils/common_utils';

export default {

  [types.SET_MAIN_ENDPOINT](state, endpoint) {
    Object.assign(state, { endpoint });
  },

  [types.SET_REPOS_LIST](state, list) {
    Object.assign(state, {
      repos: list.map(el => ({
        canDelete: !!el.destroy_path,
        destroyPath: el.destroy_path,
        id: el.id,
        isLoading: false,
        list: [],
        location: el.location,
        name: el.path,
        tagsPath: el.tags_path,
      })),
    });
  },

  [types.TOGGLE_MAIN_LOADING](state) {
    Object.assign(state, { isLoading: !state.isLoading });
  },

  [types.SET_REGISTRY_LIST](state, { repo, resp, headers }) {
    const listToUpdate = state.repos.find(el => el.id === repo.id);

    const normalizedHeaders = normalizeHeaders(headers);
    const pagination = parseIntPagination(normalizedHeaders);

    listToUpdate.pagination = pagination;

    listToUpdate.list = resp.map(element => ({
      tag: element.name,
      revision: element.revision,
      shortRevision: element.short_revision,
      size: element.total_size,
      layers: element.layers,
      location: element.location,
      createdAt: element.created_at,
      destroyPath: element.destroy_path,
      canDelete: !!element.destroy_path,
    }));
  },

  [types.TOGGLE_REGISTRY_LIST_LOADING](state, list) {
    const listToUpdate = state.repos.find(el => el.id === list.id);
    listToUpdate.isLoading = !listToUpdate.isLoading;
  },
};
