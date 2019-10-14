import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import mutations from './mutations';
import * as getters from './getters';
import state from './state';

Vue.use(Vuex);

export default () =>
  new Vuex.Store({
    actions,
    mutations,
    getters,
    state: state(),
  });
