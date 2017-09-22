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

export const fetchList = ({ commit }, { repo, page }) => {
  commit(types.TOGGLE_REGISTRY_LIST_LOADING, repo);

  return Vue.http.get(repo.tagsPath, { params: { page } })
    .then((response) => {
      const headers = response.headers;

      return response.json().then((resp) => {
        commit(types.TOGGLE_REGISTRY_LIST_LOADING, repo);
        commit(types.SET_REGISTRY_LIST, { repo, resp, headers });
      });
    });
};

export const deleteRepo = ({ commit }, repo) => Vue.http.delete(repo.path)
  .then(res => res.json());

export const deleteRegistry = ({ commit }, image) => Vue.http.delete(image.path)
  .then(res => res.json());

export const setMainEndpoint = ({ commit }, data) => commit(types.SET_MAIN_ENDPOINT, data);
export const toggleLoading = ({ commit }) => commit(types.TOGGLE_MAIN_LOADING);
