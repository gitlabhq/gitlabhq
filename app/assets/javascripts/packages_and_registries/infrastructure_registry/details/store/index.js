import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';

Vue.use(Vuex);

export default (initialState = {}) =>
  new Vuex.Store({
    actions,
    getters,
    mutations,
    state: {
      isLoading: false,
      ...initialState,
    },
  });
