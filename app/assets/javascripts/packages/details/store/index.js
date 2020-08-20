import Vue from 'vue';
import Vuex from 'vuex';
import fetchPackageVersions from './actions';
import * as getters from './getters';
import mutations from './mutations';

Vue.use(Vuex);

export default (initialState = {}) =>
  new Vuex.Store({
    actions: {
      fetchPackageVersions,
    },
    getters,
    mutations,
    state: {
      isLoading: false,
      ...initialState,
    },
  });
