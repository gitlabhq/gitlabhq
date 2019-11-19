import Vue from 'vue';
import Vuex from 'vuex';
import state from 'ee_else_ce/boards/stores/state';
import getters from 'ee_else_ce/boards/stores/getters';
import actions from 'ee_else_ce/boards/stores/actions';
import mutations from 'ee_else_ce/boards/stores/mutations';

Vue.use(Vuex);

export const createStore = () =>
  new Vuex.Store({
    state,
    getters,
    actions,
    mutations,
  });

export default createStore();
