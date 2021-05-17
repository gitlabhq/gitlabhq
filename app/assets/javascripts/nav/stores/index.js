import Vuex from 'vuex';
import { createStoreOptions } from '~/frequent_items/store';

export const createStore = () => new Vuex.Store(createStoreOptions());
