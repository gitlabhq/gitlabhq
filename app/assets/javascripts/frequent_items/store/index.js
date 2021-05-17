import Vuex from 'vuex';
import { FREQUENT_ITEMS_DROPDOWNS } from '../constants';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

export const createFrequentItemsModule = (initState = {}) => ({
  namespaced: true,
  actions,
  getters,
  mutations,
  state: state(initState),
});

export const createStoreOptions = () => ({
  modules: FREQUENT_ITEMS_DROPDOWNS.reduce(
    (acc, { namespace, vuexModule }) =>
      Object.assign(acc, {
        [vuexModule]: createFrequentItemsModule({ dropdownType: namespace }),
      }),
    {},
  ),
});

export const createStore = () => {
  return new Vuex.Store(createStoreOptions());
};
