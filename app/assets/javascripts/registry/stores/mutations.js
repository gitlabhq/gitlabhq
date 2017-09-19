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
        isLoading: false,
        list: [],
        location: el.location,
        name: el.name,
        tagsPath: el.tags_path,
        id: el.id,
      })),
    });
  },

  [types.TOGGLE_MAIN_LOADING](state) {
    Object.assign(state, { isLoading: !state.isLoading });
  },

  [types.SET_REGISTRY_LIST](state, repo, list) {
    // mock
    list = [
      {
        name: 'centos6',
        short_revision: '0b6091a66',
        revision: '0b6091a665af68bbbbb36a3e088ec3cd6f35389deebf6d4617042d56722d76fb',
        size: 706,
        layers: 19,
        created_at: 1505828744434,
      },
      {
        name: 'centos7',
        short_revision: 'b118ab5b0',
        revision: 'b118ab5b0e90b7cb5127db31d5321ac14961d097516a8e0e72084b6cdc783b43',
        size: 679,
        layers: 19,
        created_at: 1505828744434,
      },
    ];

    const listToUpdate = state.repos.find(el => el.id === repo.id);

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

  [types.TOGGLE_REGISTRY_LIST_LOADING](state, list) {
    const listToUpdate = state.repos.find(el => el.id === list.id);
    listToUpdate.isLoading = !listToUpdate.isLoading;
  },
};
