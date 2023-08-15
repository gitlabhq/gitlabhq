import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';

import * as actions from './actions';

import * as detailsActions from './details/actions';
import * as detailsGetters from './details/getters';
import detailsMutations from './details/mutations';
import detailsState from './details/state';
import * as listActions from './list/actions';
import listMutations from './list/mutations';
import listState from './list/state';

import mutations from './mutations';

Vue.use(Vuex);

export const createStore = () =>
  new Vuex.Store({
    modules: {
      list: {
        namespaced: true,
        state: listState(),
        actions: { ...actions, ...listActions },
        mutations: { ...mutations, ...listMutations },
      },
      details: {
        namespaced: true,
        state: detailsState(),
        actions: { ...actions, ...detailsActions },
        mutations: { ...mutations, ...detailsMutations },
        getters: detailsGetters,
      },
    },
  });

export default createStore();
