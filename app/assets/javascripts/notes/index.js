import Vue from 'vue';
import notesApp from './components/notes_app.vue';
import initDiscussionFilters from './discussion_filters';
import initSortDiscussions from './sort_discussions';
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
    methods: {
      setData() {
        const notesDataset = this.$el.dataset;
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
          userData: currentUserData,
          notesData: JSON.parse(notesDataset.notesData),
        };
      },
    },
    render(createElement) {
      return createElement('notes-app', {
        props: { ...this.setData() },
      });
    },
  });

  initDiscussionFilters(store);
  initSortDiscussions(store);
});
