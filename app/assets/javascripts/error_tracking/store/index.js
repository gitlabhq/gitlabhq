import Vue from 'vue';
import Vuex from 'vuex';

import * as listActions from './list/actions';
import listMutations from './list/mutations';
import listState from './list/state';

import * as detailsActions from './details/actions';
import detailsMutations from './details/mutations';
import detailsState from './details/state';
import * as detailsGetters from './details/getters';

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
      details: {
        namespaced: true,
        state: detailsState(),
        actions: detailsActions,
        mutations: detailsMutations,
        getters: detailsGetters,
      },
    },
  });

export default createStore();
