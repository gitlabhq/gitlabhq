import Vue from 'vue';
import Vuex from 'vuex';
import state from './state';
import mutations from './mutations';
import * as actions from './actions';

Vue.use(Vuex);

export const createStore = initialState =>
  new Vuex.Store({
    actions,
    mutations,
    state: state(initialState),
  });

export default createStore;
