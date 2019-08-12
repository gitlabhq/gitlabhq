import $ from 'jquery';
import Vue from 'vue';
import { mapActions, mapState, mapGetters } from 'vuex';
import store from 'ee_else_ce/mr_notes/stores';
import notesApp from '../notes/components/notes_app.vue';
import discussionKeyboardNavigator from '../notes/components/discussion_keyboard_navigator.vue';

export default () => {
  // eslint-disable-next-line no-new
  new Vue({
    el: '#js-vue-mr-discussions',
    name: 'MergeRequestDiscussions',
    components: {
      notesApp,
    },
    store,
    data() {
      const notesDataset = document.getElementById('js-vue-mr-discussions').dataset;
      const noteableData = JSON.parse(notesDataset.noteableData);
      noteableData.noteableType = notesDataset.noteableType;
      noteableData.targetType = notesDataset.targetType;

      return {
        noteableData,
        currentUserData: JSON.parse(notesDataset.currentUserData),
        notesData: JSON.parse(notesDataset.notesData),
        helpPagePath: notesDataset.helpPagePath,
      };
    },
    computed: {
      ...mapGetters(['discussionTabCounter']),
      ...mapState({
        activeTab: state => state.page.activeTab,
      }),
    },
    watch: {
      discussionTabCounter() {
        this.updateDiscussionTabCounter();
      },
    },
    created() {
      this.setActiveTab(window.mrTabs.getCurrentAction());
    },
    mounted() {
      this.notesCountBadge = $('.issuable-details').find('.notes-tab .badge');
      $(document).on('visibilitychange', this.updateDiscussionTabCounter);
      window.mrTabs.eventHub.$on('MergeRequestTabChange', this.setActiveTab);
    },
    beforeDestroy() {
      $(document).off('visibilitychange', this.updateDiscussionTabCounter);
      window.mrTabs.eventHub.$off('MergeRequestTabChange', this.setActiveTab);
    },
    methods: {
      ...mapActions(['setActiveTab']),
      updateDiscussionTabCounter() {
        this.notesCountBadge.text(this.discussionTabCounter);
      },
    },
    render(createElement) {
      const isDiffView = this.activeTab === 'diffs';

      return createElement(discussionKeyboardNavigator, { props: { isDiffView } }, [
        createElement('notes-app', {
          props: {
            noteableData: this.noteableData,
            notesData: this.notesData,
            userData: this.currentUserData,
            shouldShow: this.activeTab === 'show',
            helpPagePath: this.helpPagePath,
          },
        }),
      ]);
    },
  });
};
