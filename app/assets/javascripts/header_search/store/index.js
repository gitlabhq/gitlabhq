import Vue from 'vue';
import Vuex from 'vuex';
import * as getters from './getters';
import createState from './state';

Vue.use(Vuex);

export const getStoreConfig = ({ issuesPath, mrPath, searchContext }) => ({
  getters,
  state: createState({ issuesPath, mrPath, searchContext }),
});

const createStore = (config) => new Vuex.Store(getStoreConfig(config));
export default createStore;
