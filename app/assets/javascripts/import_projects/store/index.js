import Vue from 'vue';
import Vuex from 'vuex';
import state from './state';
import actionsFactory from './actions';
import * as getters from './getters';
import mutations from './mutations';

Vue.use(Vuex);

export default ({ initialState, endpoints }) =>
  new Vuex.Store({
    state: { ...state(), ...initialState },
    actions: actionsFactory({ endpoints }),
    mutations,
    getters,
  });
