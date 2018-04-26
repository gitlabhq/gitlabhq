import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import module from './modules';

Vue.use(Vuex);

export default new Vuex.Store({
  state: module.state,
  actions,
  getters,
  mutations,
});
