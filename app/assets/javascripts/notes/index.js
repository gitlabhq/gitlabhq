import Vue from 'vue';
import notesApp from './components/notes_app.vue';
import initDiscussionFilters from './discussion_filters';
import initSortDiscussions from './sort_discussions';
import { store } from './stores';
import initTimelineToggle from './timeline';

const el = document.getElementById('js-vue-notes');

if (el) {
  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      notesApp,
    },
    store,
    data() {
      const notesDataset = el.dataset;
      const parsedUserData = JSON.parse(notesDataset.currentUserData);
      const noteableData = JSON.parse(notesDataset.noteableData);
      let currentUserData = {};

      noteableData.noteableType = notesDataset.noteableType;
      noteableData.targetType = notesDataset.targetType;
      if (noteableData.discussion_locked === null) {
        // discussion_locked has never been set for this issuable.
        // set to `false` for safety.
        noteableData.discussion_locked = false;
      }

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
  });

  initDiscussionFilters(store);
  initSortDiscussions(store);
  initTimelineToggle(store);
}
