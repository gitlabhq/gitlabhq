import * as types from './mutation_types';

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
        name: el.name,
        tagsPath: el.tags_path,
      })),
    });
  },

  [types.TOGGLE_MAIN_LOADING](state) {
    Object.assign(state, { isLoading: !state.isLoading });
  },

  [types.SET_REGISTRY_LIST](state, repo, list) {
    const listToUpdate = state.repos.find(el => el.id === repo.id);

    listToUpdate.list = list.map(element => ({
      tag: element.name,
      revision: element.revision,
      shortRevision: element.short_revision,
      size: element.size,
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
