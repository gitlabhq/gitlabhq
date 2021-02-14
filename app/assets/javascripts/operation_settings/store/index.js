import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import mutations from './mutations';
import createState from './state';

Vue.use(Vuex);

export const createStore = (initialState) =>
  new Vuex.Store({
    state: createState(initialState),
    actions,
    mutations,
  });

export default createStore;
