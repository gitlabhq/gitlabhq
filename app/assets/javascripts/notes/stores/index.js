import Vue from 'vue';
import Vuex from 'vuex';
import notesModule from './modules';

Vue.use(Vuex);

export default () =>
  new Vuex.Store(notesModule());
