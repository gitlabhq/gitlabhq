import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import mutations from './mutations';
import createState from './state';

Vue.use(Vuex);

export default (initialState) =>
  new Vuex.Store({
    actions,
    mutations,
    state: createState(initialState),
  });
