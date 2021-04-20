import Vue from 'vue';
import Vuex from 'vuex';
import batchCommentsModule from '~/batch_comments/stores/modules/batch_comments';
import diffsModule from '~/diffs/store/modules';
import notesModule from '~/notes/stores/modules';

Vue.use(Vuex);

export default function createDiffsStore() {
  return new Vuex.Store({
    modules: {
      diffs: diffsModule(),
      notes: notesModule(),
      batchComments: batchCommentsModule(),
    },
  });
}
