import Vue from 'vue';
import issueNotesApp from './components/issue_notes_app.vue';

document.addEventListener('DOMContentLoaded', () => {
  const vm = new Vue({
    el: '#js-vue-notes',
    components: {
      issueNotesApp,
    },
    data() {
      const notesDataset = document.getElementById('js-vue-notes').dataset;

      return {
        issueData: JSON.parse(notesDataset.issueData),
        currentUserData: JSON.parse(notesDataset.currentUserData),
        notesData: {
          lastFetchedAt: notesDataset.lastFetchedAt,
          discussionsPath: notesDataset.discussionsPath,
          newSessionPath: notesDataset.newSessionPath,
          registerPath: notesDataset.registerPath,
          notesPath: notesDataset.notesPath,
          markdownDocs: notesDataset.markdownDocs,
          quickActionsDocs: notesDataset.quickActionsDocs,
        },
      };
    },
    render(createElement) {
      return createElement('issue-notes-app', {
        attrs: {
          ref: 'notes',
        },
        props: {
          issueData: this.issueData,
          notesData: this.notesData,
          userData: this.currentUserData,
        },
      });
    },
  });

  // This is used in note_polling_spec
  window.issueNotes = {
    refresh() {
      vm.$refs.notes.$store.dispatch('poll');
    },
  };
});

