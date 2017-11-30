import Vue from 'vue';
import notesApp from './components/notes_app.vue';

document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '#js-vue-notes',
  components: {
    notesApp,
  },
  data() {
    const notesDataset = document.getElementById('js-vue-notes').dataset;

    return {
      noteableData: JSON.parse(notesDataset.noteableData),
      currentUserData: JSON.parse(notesDataset.currentUserData),
      notesData: {
        lastFetchedAt: notesDataset.lastFetchedAt,
        discussionsPath: notesDataset.discussionsPath,
        newSessionPath: notesDataset.newSessionPath,
        registerPath: notesDataset.registerPath,
        notesPath: notesDataset.notesPath,
        markdownDocsPath: notesDataset.markdownDocsPath,
        quickActionsDocsPath: notesDataset.quickActionsDocsPath,
      },
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
}));
