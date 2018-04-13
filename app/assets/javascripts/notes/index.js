import Vue from 'vue';
import Vuex from 'vuex';
import notesApp from './components/notes_app.vue';
import storeConfig from './stores';

Vue.use(Vuex);

const store = new Vuex.Store({
  modules: {
    notes: storeConfig,
  },
});

document.addEventListener(
  'DOMContentLoaded',
  () =>
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
      render(createElement) {
        return createElement('notes-app', {
          props: {
            noteableData: this.noteableData,
            notesData: this.notesData,
            userData: this.currentUserData,
          },
        });
      },
    }),
);
