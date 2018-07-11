import Vue from 'vue';
import Vuex from 'vuex';
import state from './state';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import commitModule from './modules/commit';
import pipelines from './modules/pipelines';
import mergeRequests from './modules/merge_requests';

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
      mergeRequests,
    },
  });

export default createStore();
