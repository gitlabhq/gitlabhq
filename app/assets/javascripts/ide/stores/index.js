import Vue from 'vue';
import Vuex from 'vuex';
import state from './state';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import commitModule from './modules/commit';

Vue.use(Vuex);

export default new Vuex.Store({
  state: state(),
  actions,
  mutations,
  getters,
  modules: {
    commit: commitModule,
  },
});
