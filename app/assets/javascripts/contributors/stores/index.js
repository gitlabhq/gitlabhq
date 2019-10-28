import Vue from 'vue';
import Vuex from 'vuex';
import state from './state';
import mutations from './mutations';
import * as getters from './getters';
import * as actions from './actions';

Vue.use(Vuex);

export const createStore = () =>
  new Vuex.Store({
    actions,
    mutations,
    getters,
    state: state(),
  });

export default createStore();
