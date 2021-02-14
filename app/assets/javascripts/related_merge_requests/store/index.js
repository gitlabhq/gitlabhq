import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import mutations from './mutations';
import createState from './state';

Vue.use(Vuex);

export default () =>
  new Vuex.Store({
    state: createState(),
    actions,
    mutations,
  });
