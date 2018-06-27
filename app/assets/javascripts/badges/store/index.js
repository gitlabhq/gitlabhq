import Vue from 'vue';
import Vuex from 'vuex';
import createState from './state';
import actions from './actions';
import mutations from './mutations';

Vue.use(Vuex);

export default new Vuex.Store({
  state: createState(),
  actions,
  mutations,
});
