import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import batchCommentsModule from '~/batch_comments/stores/modules/batch_comments';
import diffsModule from '~/diffs/store/modules';
import notesModule from '~/notes/stores/modules';
import mrPageModule from './modules';
import findingsDrawer from './drawer';

Vue.use(Vuex);

export const createModules = () => ({
  page: mrPageModule(),
  notes: notesModule(),
  diffs: diffsModule(),
  batchComments: batchCommentsModule(),
  findingsDrawer: findingsDrawer(),
});

export const createStore = () =>
  new Vuex.Store({
    modules: createModules(),
  });

export default createStore();
