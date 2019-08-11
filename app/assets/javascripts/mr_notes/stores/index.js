import Vue from 'vue';
import Vuex from 'vuex';
import notesModule from '~/notes/stores/modules';
import diffsModule from '~/diffs/store/modules';
import mrPageModule from './modules';

Vue.use(Vuex);

export const createStore = () =>
  new Vuex.Store({
    modules: {
      page: mrPageModule(),
      notes: notesModule(),
      diffs: diffsModule(),
    },
  });

export default createStore();
