import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import actions from './actions';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

export const createStore = () => ({
  actions,
  mutations,
  state: state(),
});

export default new Vuex.Store(createStore());
