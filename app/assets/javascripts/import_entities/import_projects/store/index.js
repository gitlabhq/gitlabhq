import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import actionsFactory from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

export default ({ initialState, endpoints }) =>
  new Vuex.Store({
    state: { ...state(), ...initialState },
    actions: actionsFactory({ endpoints }),
    mutations,
    getters,
  });
