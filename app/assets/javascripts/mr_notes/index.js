import Vue from 'vue';
import notesApp from '../notes/components/notes_app.vue';
import discussionCounter from '../notes/components/discussion_counter.vue';
import store from '../notes/stores';

export default function initMrNotes() {
  // eslint-disable-next-line no-new
  new Vue({
    el: '#js-vue-mr-discussions',
    components: {
      notesApp,
    },
    data() {
      const notesDataset = document.getElementById('js-vue-mr-discussions')
        .dataset;
      return {
        noteableData: JSON.parse(notesDataset.noteableData),
        currentUserData: JSON.parse(notesDataset.currentUserData),
        notesData: JSON.parse(notesDataset.notesData),
      };
    },
    render(createElement) {
      return createElement('notes-app', {
        props: {
          noteableData: this.noteableData,
          notesData: this.notesData,
          userData: this.currentUserData,
        },
      });
    },
  });

  // eslint-disable-next-line no-new
  new Vue({
    el: '#js-vue-discussion-counter',
    components: {
      discussionCounter,
    },
    store,
    render(createElement) {
      return createElement('discussion-counter');
    },
  });
}
