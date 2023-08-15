import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import createState from './state';

Vue.use(Vuex);

export const getStoreConfig = (storeInitValues) => ({
  actions,
  getters,
  mutations,
  state: createState(storeInitValues),
});

const createStore = (config) => new Vuex.Store(getStoreConfig(config));
export default createStore;
