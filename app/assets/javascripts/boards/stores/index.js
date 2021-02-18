import Vue from 'vue';
import Vuex from 'vuex';
import actions from 'ee_else_ce/boards/stores/actions';
import getters from 'ee_else_ce/boards/stores/getters';
import mutations from 'ee_else_ce/boards/stores/mutations';
import state from 'ee_else_ce/boards/stores/state';

Vue.use(Vuex);

export const createStore = () =>
  new Vuex.Store({
    state,
    getters,
    actions,
    mutations,
  });

export default createStore();
