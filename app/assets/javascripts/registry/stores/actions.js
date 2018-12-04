import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';


export const fetchRepos = ({ commit, state }) => {
  commit(types.TOGGLE_MAIN_LOADING);

  return axios
    .get(state.endpoint)
    .then(({ data }) => {
      commit(types.TOGGLE_MAIN_LOADING);
      commit(types.SET_REPOS_LIST, data);
    });
};

export const fetchList = ({ commit }, { repo, page }) => {
  commit(types.TOGGLE_REGISTRY_LIST_LOADING, repo);

  return axios.get(repo.tagsPath, { params: { page } }).then(response => {
    const { headers, data } = response;

    commit(types.TOGGLE_REGISTRY_LIST_LOADING, repo);
    commit(types.SET_REGISTRY_LIST, { repo, resp: data, headers });
  });
};

// eslint-disable-next-line no-unused-vars
export const deleteRepo = ({ commit }, repo) => axios.delete(repo.destroyPath);

// eslint-disable-next-line no-unused-vars
export const deleteRegistry = ({ commit }, image) => axios.delete(image.destroyPath);

export const setMainEndpoint = ({ commit }, data) => commit(types.SET_MAIN_ENDPOINT, data);
export const toggleLoading = ({ commit }) => commit(types.TOGGLE_MAIN_LOADING);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
