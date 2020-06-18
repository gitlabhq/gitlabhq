import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

export const monitoringDashboard = {
  namespaced: true,
  actions,
  getters,
  mutations,
  state,
};

export const createStore = (initState = {}) =>
  new Vuex.Store({
    modules: {
      monitoringDashboard: {
        ...monitoringDashboard,
        state: {
          ...state(),
          ...initState,
        },
      },
    },
  });
