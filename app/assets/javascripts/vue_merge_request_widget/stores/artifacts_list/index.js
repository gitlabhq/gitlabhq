import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

export const getStoreConfig = () => ({
  actions,
  mutations,
  getters,
  state: state(),
});

export default () => new Vuex.Store(getStoreConfig());
