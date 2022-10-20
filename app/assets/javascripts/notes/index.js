import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import NotesApp from './components/notes_app.vue';
import { store } from './stores';
import { getNotesFilterData } from './utils/get_notes_filter_data';

export default () => {
  const el = document.getElementById('js-vue-notes');
  if (!el) {
    return;
  }

  const notesFilterProps = getNotesFilterData(el);
  const showTimelineViewToggle = parseBoolean(el.dataset.showTimelineViewToggle);

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'NotesRoot',
    components: {
      NotesApp,
    },
    store,
    provide: {
      showTimelineViewToggle,
    },
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
          can_add_timeline_events: parseBoolean(notesDataset.canAddTimelineEvents),
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
          ...notesFilterProps,
        },
      });
    },
  });
};
