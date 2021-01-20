import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import mutations from './mutations';
import createState from './state';

Vue.use(Vuex);

export const getStoreConfig = ({ query }) => ({
  actions,
  mutations,
  state: createState({ query }),
});

const createStore = (config) => new Vuex.Store(getStoreConfig(config));
export default createStore;
