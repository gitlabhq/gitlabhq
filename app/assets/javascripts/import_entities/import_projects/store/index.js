import Vue from 'vue';
import Vuex from 'vuex';
import actionsFactory from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

export default ({ initialState, endpoints, hasPagination }) =>
  new Vuex.Store({
    state: { ...state(), ...initialState },
    actions: actionsFactory({ endpoints, hasPagination }),
    mutations,
    getters,
  });
