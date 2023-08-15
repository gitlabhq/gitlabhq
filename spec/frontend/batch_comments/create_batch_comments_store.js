import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import batchCommentsModule from '~/batch_comments/stores/modules/batch_comments';
import notesModule from '~/notes/stores/modules';

Vue.use(Vuex);

export default function createDiffsStore() {
  return new Vuex.Store({
    modules: {
      notes: notesModule(),
      batchComments: batchCommentsModule(),
    },
  });
}
