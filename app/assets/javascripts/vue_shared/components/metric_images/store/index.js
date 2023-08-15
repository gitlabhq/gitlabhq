import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import actionsFactory from './actions';
import mutations from './mutations';
import createState from './state';

Vue.use(Vuex);

export default (initialState, service) =>
  new Vuex.Store({
    actions: actionsFactory(service),
    mutations,
    state: createState(initialState),
  });
