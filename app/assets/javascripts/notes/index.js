import Vue from 'vue';
import issueNotesApp from './components/issue_notes_app.vue';

document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '#js-vue-notes',
  components: {
    issueNotesApp,
  },
  data() {
    const notesDataset = document.getElementById('js-vue-notes').dataset;
    const parsedUserData = JSON.parse(notesDataset.currentUserData);
    const currentUserData = parsedUserData ? {
      id: parsedUserData.id,
      name: parsedUserData.name,
      username: parsedUserData.username,
      avatar_url: parsedUserData.avatar_path || parsedUserData.avatar_url,
      path: parsedUserData.path,
    } : {};

    return {
      noteableData: JSON.parse(notesDataset.noteableData),
      currentUserData,
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
    return createElement('issue-notes-app', {
      props: {
        noteableData: this.noteableData,
        notesData: this.notesData,
        userData: this.currentUserData,
      },
    });
  },
}));
