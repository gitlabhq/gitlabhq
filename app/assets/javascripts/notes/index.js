import Vue from 'vue';
import notesApp from './components/notes_app.vue';
import createStore from './stores';

document.addEventListener('DOMContentLoaded', () => {
  const store = createStore();

  return new Vue({
    el: '#js-vue-notes',
    components: {
      notesApp,
    },
    store,
    data() {
      const notesDataset = document.getElementById('js-vue-notes').dataset;
      const parsedUserData = JSON.parse(notesDataset.currentUserData);
      const noteableData = JSON.parse(notesDataset.noteableData);
      const markdownVersion = parseInt(notesDataset.markdownVersion, 10);
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
        markdownVersion,
        notesData: JSON.parse(notesDataset.notesData),
      };
    },
    render(createElement) {
      return createElement('notes-app', {
        props: {
          noteableData: this.noteableData,
          notesData: this.notesData,
          userData: this.currentUserData,
          markdownVersion: this.markdownVersion,
        },
      });
    },
  });
});
