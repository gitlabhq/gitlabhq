import Vue from 'vue';
import Vuex from 'vuex';
import createState from './state';

Vue.use(Vuex);

export const getStoreConfig = ({ query }) => ({
  state: createState({ query }),
});

const createStore = config => new Vuex.Store(getStoreConfig(config));
export default createStore;
