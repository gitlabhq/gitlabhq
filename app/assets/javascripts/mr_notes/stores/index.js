import Vue from 'vue';
import Vuex from 'vuex';
import notesModule from '~/notes/stores/modules';
import diffsModule from '~/diffs/store/modules';
import mrPageModule from './modules';

Vue.use(Vuex);

export default new Vuex.Store({
  modules: {
    page: mrPageModule,
    notes: notesModule,
    diffs: diffsModule,
  },
});
