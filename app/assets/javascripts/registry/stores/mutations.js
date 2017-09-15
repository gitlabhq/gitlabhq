import * as types from './mutation_types';

export default {
  [types.SET_REPOS_LIST](state, list) {
    Object.assign(state, {
      repos: list.map(el => ({
        name: el.name,
        isLoading: false,
        canDelete: !!el.destroy_path,
        destroyPath: el.destroy_path,
        list: [],
      })),
    });
  },

  [types.TOGGLE_MAIN_LOADING](state) {
    Object.assign(state, { isLoading: !state.isLoading });
  },

  [types.SET_IMAGES_LIST](state, image, list) {
    const listToUpdate = state.repos.find(el => el.name === image.name);
    listToUpdate.list = list.map(element => ({
      tag: element.name,
      revision: element.revision,
      shortRevision: element.short_revision,
      size: element.size,
      layers: element.layers,
      createdAt: element.created_at,
      destroyPath: element.destroy_path,
      canDelete: !!element.destroy_path,
    }));
  },

  [types.TOGGLE_IMAGE_LOADING](state, image) {
    const listToUpdate = state.repos.find(el => el.name === image.name);
    listToUpdate.isLoading = !listToUpdate.isLoading;
  },
};
