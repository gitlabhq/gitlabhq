import Vue from 'vue';
import VueResource from 'vue-resource';
import * as types from './mutation_types';

Vue.use(VueResource);

export const fetchRepos = ({ commit, state }) => {
  commit(types.TOGGLE_MAIN_LOADING);

  return Vue.http.get(state.endpoint)
    .then(res => res.json())
    .then((response) => {
      commit(types.TOGGLE_MAIN_LOADING);
      commit(types.SET_REPOS_LIST, response);
    });
};

export const fetchList = ({ commit }, list) => {
  commit(types.TOGGLE_IMAGE_LOADING, list);

  return Vue.http.get(list.path)
    .then(res => res.json())
    .then((response) => {
      commit(types.TOGGLE_IMAGE_LOADING, list);
      commit(types.SET_IMAGES_LIST, list, response);
    });
};

export const deleteRepo = ({ commit }, repo) => Vue.http.delete(repo.path)
  .then(res => res.json())
  .then(() => {
    commit(types.DELETE_REPO, repo);
  });

export const deleteImage = ({ commit }, image) => Vue.http.delete(image.path)
  .then(res => res.json())
  .then(() => {
    commit(types.DELETE_IMAGE, image);
  });
