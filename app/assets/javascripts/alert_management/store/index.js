import Vue from 'vue';
import Vuex from 'vuex';

import * as listActions from './list/actions';
import listMutations from './list/mutations';
import listState from './list/state';

Vue.use(Vuex);

export const createStore = () =>
  new Vuex.Store({
    modules: {
      list: {
        namespaced: true,
        state: listState(),
        actions: listActions,
        mutations: listMutations,
      },
    },
  });

export default createStore();
