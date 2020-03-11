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
      environmentLogs: {
        namespaced: true,
        actions,
        mutations,
        state: state(),
        getters,
      },
    },
  });

export default createStore;
