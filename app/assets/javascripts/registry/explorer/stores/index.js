import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

// eslint-disable-next-line import/prefer-default-export
export const createStore = () =>
  new Vuex.Store({
    state,
    getters,
    actions,
    mutations,
  });
