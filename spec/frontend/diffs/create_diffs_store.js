import Vue from 'vue';
import Vuex from 'vuex';
import diffsModule from '~/diffs/store/modules';
import notesModule from '~/notes/stores/modules';

Vue.use(Vuex);

export default function createDiffsStore() {
  return new Vuex.Store({
    modules: {
      diffs: diffsModule(),
      notes: notesModule(),
    },
  });
}
