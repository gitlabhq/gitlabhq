import Vue from 'vue';
import Vuex from 'vuex';
import state from './state';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import commitModule from './modules/commit';
import pipelines from './modules/pipelines';

Vue.use(Vuex);

export const createStore = () =>
  new Vuex.Store({
    state: state(),
    actions,
    mutations,
    getters,
    modules: {
      commit: commitModule,
      pipelines,
    },
  });

export default createStore();
