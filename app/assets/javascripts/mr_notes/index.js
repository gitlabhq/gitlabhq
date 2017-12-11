import Vue from 'vue';
import notesApp from '../notes/components/notes_app.vue';

document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '#js-vue-mr-discussions',
  components: {
    notesApp,
  },
  data() {
    const notesDataset = document.getElementById('js-vue-mr-discussions').dataset;
    return {
      issueData: JSON.parse(notesDataset.issueData),
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
        noteableData: this.issueData,
        notesData: this.notesData,
        userData: this.currentUserData,
      },
    });
  },
}));
