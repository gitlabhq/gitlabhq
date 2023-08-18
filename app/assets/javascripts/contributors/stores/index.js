import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

export const createStore = (defaultBranch) =>
  new Vuex.Store({
    actions,
    mutations,
    getters,
    state: state(defaultBranch),
  });

export default createStore;
