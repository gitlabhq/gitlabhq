import Vue from 'vue';
import initNoteStats from 'ee_else_ce/event_tracking/notes';
import notesApp from './components/notes_app.vue';
import initDiscussionFilters from './discussion_filters';
import createStore from './stores';

document.addEventListener('DOMContentLoaded', () => {
  const store = createStore();

  // eslint-disable-next-line no-new
  new Vue({
    el: '#js-vue-notes',
    components: {
      notesApp,
    },
    store,
    data() {
      const notesDataset = document.getElementById('js-vue-notes').dataset;
      const parsedUserData = JSON.parse(notesDataset.currentUserData);
      const noteableData = JSON.parse(notesDataset.noteableData);
      let currentUserData = {};

      noteableData.noteableType = notesDataset.noteableType;
      noteableData.targetType = notesDataset.targetType;

      if (parsedUserData) {
        currentUserData = {
          id: parsedUserData.id,
          name: parsedUserData.name,
          username: parsedUserData.username,
          avatar_url: parsedUserData.avatar_path || parsedUserData.avatar_url,
          path: parsedUserData.path,
        };
      }

      return {
        noteableData,
        currentUserData,
        notesData: JSON.parse(notesDataset.notesData),
      };
    },
    mounted() {
      initNoteStats();
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

  initDiscussionFilters(store);
});
