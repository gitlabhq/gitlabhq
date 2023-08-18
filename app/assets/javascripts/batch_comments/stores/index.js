import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import batchComments from './modules/batch_comments';

Vue.use(Vuex);

export const createStore = () =>
  new Vuex.Store({
    modules: {
      batchComments: batchComments(),
    },
  });

export default createStore();
