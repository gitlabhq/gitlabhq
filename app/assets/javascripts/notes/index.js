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

    function camelize(string) {
      return string.replace(/(_\w)/g, match => match[1].toUpperCase());
    }

    function camelizeKeys(notesData) {
      return Object.keys(notesData).reduce(
        (acc, curr) => ({
          ...acc,
          [camelize(curr)]: notesData[curr],
        }),
        {},
      );
    }

    const notesDataOrig = JSON.parse(notesDataset.notesData);
    const notesData = camelizeKeys(notesDataOrig);

    return {
      noteableData: JSON.parse(notesDataset.noteableData),
      currentUserData,
      notesData,
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
