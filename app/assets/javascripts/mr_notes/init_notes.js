import Vue from 'vue';
import VueApollo from 'vue-apollo';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState, mapGetters } from 'vuex';
import { apolloProvider } from '~/graphql_shared/issuable_client';

import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { parseBoolean } from '~/lib/utils/common_utils';
import store from '~/mr_notes/stores';
import { pinia } from '~/pinia/instance';
import notesEventHub from '~/notes/event_hub';
import discussionNavigator from '../notes/components/discussion_navigator.vue';
import NotesApp from '../notes/components/notes_app.vue';
import { getNotesFilterData } from '../notes/utils/get_notes_filter_data';
import initWidget from '../vue_merge_request_widget';

export default () => {
  requestIdleCallback(
    () => {
      renderGFM(document.getElementById('diff-notes-app'));
    },
    { timeout: 500 },
  );

  const el = document.getElementById('js-vue-mr-discussions');
  if (!el) {
    return;
  }

  Vue.use(VueApollo);

  const notesFilterProps = getNotesFilterData(el);
  const notesDataset = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'MergeRequestDiscussions',
    components: {
      NotesApp,
    },
    pinia,
    store,
    apolloProvider,
    provide: {
      reportAbusePath: notesDataset.reportAbusePath,
      newCommentTemplatePaths: JSON.parse(notesDataset.newCommentTemplatePaths),
      mrFilter: true,
      newCustomEmojiPath: notesDataset.newCustomEmojiPath,
    },
    data() {
      const noteableData = JSON.parse(notesDataset.noteableData);
      noteableData.noteableType = notesDataset.noteableType;
      noteableData.targetType = notesDataset.targetType;
      noteableData.discussion_locked = parseBoolean(notesDataset.isLocked);

      return {
        noteableData,
        endpoints: {
          metadata: notesDataset.endpointMetadata,
        },
        notesData: JSON.parse(notesDataset.notesData),
        helpPagePath: notesDataset.helpPagePath,
      };
    },
    computed: {
      ...mapGetters(['isNotesFetched']),
      ...mapState({
        activeTab: (state) => state.page.activeTab,
      }),
      isShowTabActive() {
        return this.activeTab === 'show';
      },
    },
    watch: {
      isShowTabActive: {
        handler(newVal) {
          if (newVal) {
            initWidget();
          }
        },
        immediate: true,
      },
    },
    created() {
      this.setEndpoints(this.endpoints);

      if (!this.isNotesFetched) {
        notesEventHub.$emit('fetchNotesData');
      }

      this.fetchMrMetadata();
    },
    methods: {
      ...mapActions(['setEndpoints', 'fetchMrMetadata']),
    },
    render(createElement) {
      // NOTE: Even though `discussionNavigator` is added to the `notes-app`,
      // it adds a global key listener so it works on the diffs tab as well.
      // If we create a single Vue app for all of the MR tabs, we should move this
      // up the tree, to the root.
      return createElement(discussionNavigator, [
        createElement('notes-app', {
          props: {
            noteableData: this.noteableData,
            notesData: this.notesData,
            userData: this.currentUserData,
            shouldShow: this.isShowTabActive,
            helpPagePath: this.helpPagePath,
            ...notesFilterProps,
          },
        }),
      ]);
    },
  });
};
