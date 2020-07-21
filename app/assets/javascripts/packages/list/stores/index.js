import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import getList from './getters';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

export const createStore = () =>
  new Vuex.Store({
    state,
    getters: {
      getList,
    },
    actions,
    mutations,
  });

export default createStore();
