import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import actions from 'ee_else_ce/boards/stores/actions';
import getters from 'ee_else_ce/boards/stores/getters';
import mutations from 'ee_else_ce/boards/stores/mutations';
import state from 'ee_else_ce/boards/stores/state';

Vue.use(Vuex);

export const storeOptions = {
  state,
  getters,
  actions,
  mutations,
};

export const createStore = (options = storeOptions) => new Vuex.Store(options);

export default createStore();
