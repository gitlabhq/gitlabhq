import Vue from 'vue';
import Vuex from 'vuex';
import state from './state';

Vue.use(Vuex);

export const createStore = initialState =>
  new Vuex.Store({
    state: state(initialState),
  });

export default createStore;
