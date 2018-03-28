import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

const store = new Vuex.Store({
  actions,
  getters,
  mutations,
  state: state(),
});

export default store;
