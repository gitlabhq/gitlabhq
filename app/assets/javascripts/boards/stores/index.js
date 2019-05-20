import Vue from 'vue';
import Vuex from 'vuex';
import state from 'ee_else_ce/boards/stores/state';
import actions from 'ee_else_ce/boards/stores/actions';
import mutations from 'ee_else_ce/boards/stores/mutations';

Vue.use(Vuex);

export default () =>
  new Vuex.Store({
    state,
    actions,
    mutations,
  });
