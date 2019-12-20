import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

export const createStore = () =>
  new Vuex.Store({
    modules: {
      monitoringDashboard: {
        namespaced: true,
        actions,
        getters,
        mutations,
        state,
      },
    },
  });

export default createStore();
