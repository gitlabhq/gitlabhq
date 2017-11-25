import Vue from 'vue';
import Vuex from 'vuex';
import createPersistedState from 'vuex-persistedstate';
import state from './state';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';

Vue.use(Vuex);

export default new Vuex.Store({
  state: state(),
  actions,
  mutations,
  getters,
  plugins: [createPersistedState({
    key: 'gitlab-ide',
  })],
});
