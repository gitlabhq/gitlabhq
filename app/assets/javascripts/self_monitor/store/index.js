import Vue from 'vue';
import Vuex from 'vuex';
import createState from './state';
import * as actions from './actions';
import mutations from './mutations';

Vue.use(Vuex);

export const createStore = initialState =>
  new Vuex.Store({
    modules: {
      selfMonitoring: {
        namespaced: true,
        state: createState(initialState),
        actions,
        mutations,
      },
    },
  });

export default createStore;
