import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';

Vue.use(Vuex);

export default new Vuex.Store({
  state: {
    isLoading: false,
    endpoint: '', // initial endpoint to fetch the repos list
    /**
     * Each object in `repos` has the following strucure:
     * {
     *   name: String,
     *   isLoading: Boolean,
     *   tagsPath: String // endpoint to request the list
     *   destroyPath: String // endpoit to delete the repo
     *   list: Array // List of the registry images
     * }
     *
     * Each registry image inside `list` has the following structure:
     * {
     *   tag: String,
     *   revision: String
     *   shortRevision: String
     *   size: Number
     *   layers: Number
     *   createdAt: String
     *   destroyPath: String // endpoit to delete each image
     * }
     */
    repos: [],
  },
  actions,
  getters,
  mutations,
});
