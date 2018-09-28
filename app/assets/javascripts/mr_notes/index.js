import $ from 'jquery';
import Vue from 'vue';
import { mapActions, mapState, mapGetters } from 'vuex';
import initDiffsApp from '../diffs';
import notesApp from '../notes/components/notes_app.vue';
import discussionCounter from '../notes/components/discussion_counter.vue';
import store from './stores';
import MergeRequest from '../merge_request';

export default function initMrNotes() {
  const mrShowNode = document.querySelector('.merge-request');
  // eslint-disable-next-line no-new
  new MergeRequest({
    action: mrShowNode.dataset.mrAction,
  });

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
      return createElement('notes-app', {
        props: {
          noteableData: this.noteableData,
          notesData: this.notesData,
          userData: this.currentUserData,
          shouldShow: this.activeTab === 'show',
        },
      });
    },
  });

  // eslint-disable-next-line no-new
  new Vue({
    el: '#js-vue-discussion-counter',
    name: 'DiscussionCounter',
    components: {
      discussionCounter,
    },
    store,
    render(createElement) {
      return createElement('discussion-counter');
    },
  });

  initDiffsApp(store);
}
