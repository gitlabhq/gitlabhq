import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

// In practice this store will have a number of `monitoringDashboard` modules added dynamically
export const createStore = () =>
  new Vuex.Store({
    modules: {
      embedGroup: {
        namespaced: true,
        actions,
        getters,
        mutations,
        state,
      },
    },
  });
