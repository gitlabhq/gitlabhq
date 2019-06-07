import Vue from 'vue';
import Vuex from 'vuex';
import createState from './state';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';

Vue.use(Vuex);

export default () =>
  new Vuex.Store({
    state: createState(),
    actions,
    getters,
    mutations,
  });
