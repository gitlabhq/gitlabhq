import Vue from 'vue';
import Vuex from 'vuex';
import indexModule from './modules/index';
import newModule from './modules/new';
import editModule from './modules/edit';

Vue.use(Vuex);

export const createStore = () =>
  new Vuex.Store({
    modules: {
      index: indexModule,
      new: newModule,
      edit: editModule,
    },
  });

export default createStore();
