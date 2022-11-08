import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import createState from './state';

Vue.use(Vuex);

export const getStoreConfig = ({ query, navigation }) => ({
  actions,
  getters,
  mutations,
  state: createState({ query, navigation }),
});

const createStore = (config) => new Vuex.Store(getStoreConfig(config));
export default createStore;
