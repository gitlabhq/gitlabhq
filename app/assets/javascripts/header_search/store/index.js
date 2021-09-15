import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import createState from './state';

Vue.use(Vuex);

export const getStoreConfig = ({ searchPath, issuesPath, mrPath, searchContext }) => ({
  actions,
  getters,
  mutations,
  state: createState({ searchPath, issuesPath, mrPath, searchContext }),
});

const createStore = (config) => new Vuex.Store(getStoreConfig(config));
export default createStore;
