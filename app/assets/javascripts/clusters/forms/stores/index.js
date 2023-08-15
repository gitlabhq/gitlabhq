import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import state from './state';

Vue.use(Vuex);

export const createStore = (initialState) =>
  new Vuex.Store({
    state: state(initialState),
  });

export default createStore;
