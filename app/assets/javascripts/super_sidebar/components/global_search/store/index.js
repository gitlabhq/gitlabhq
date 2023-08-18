import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import createState from './state';

Vue.use(Vuex);

export const getStoreConfig = ({
  searchPath,
  issuesPath,
  mrPath,
  autocompletePath,
  searchContext,
  search,
}) => ({
  actions,
  getters,
  mutations,
  state: createState({ searchPath, issuesPath, mrPath, autocompletePath, searchContext, search }),
});

const createStore = (config) => new Vuex.Store(getStoreConfig(config));
export default createStore;
