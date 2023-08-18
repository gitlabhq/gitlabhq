import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
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
