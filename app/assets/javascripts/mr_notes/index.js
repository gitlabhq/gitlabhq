import Vue from 'vue';
import Vuex, { mapActions, mapGetters } from 'vuex';
import notesApp from '../notes/components/notes_app.vue';
import diffsApp from '../diffs/components/app.vue';
import discussionCounter from '../notes/components/discussion_counter.vue';
import notesStoreConfig from '../notes/stores';
import diffsStoreConfig from '../diffs/store';
import mrPageStoreConfig from './stores';
import MergeRequest from '../merge_request';

Vue.use(Vuex);

const store = new Vuex.Store({
  modules: {
    page: mrPageStoreConfig,
    notes: notesStoreConfig,
  },
});

export default function initMrNotes() {
  const mrShowNode = document.querySelector('.merge-request');
  window.mergeRequest = new MergeRequest({
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
      const notesDataset = document.getElementById('js-vue-mr-discussions')
        .dataset;

      return {
        noteableData: JSON.parse(notesDataset.noteableData),
        currentUserData: JSON.parse(notesDataset.currentUserData),
        notesData: JSON.parse(notesDataset.notesData),
      };
    },
    computed: {
      ...mapGetters(['activeTab']),
    },
    mounted() {
      this.setActiveTab(window.mrTabs.getCurrentAction());

      window.mrTabs.eventHub.$on('MergeRequestTabChange', tab => {
        this.setActiveTab(tab);
      });
    },
    methods: {
      ...mapActions(['setActiveTab']),
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

  // eslint-disable-next-line no-new
  new Vue({
    el: '#js-diffs-app',
    name: 'DiffsApp',
    components: {
      diffsApp,
    },
    store,
    data() {
      const { dataset } = document.querySelector(this.$options.el);

      return {
        endpoint: dataset.endpoint,
      };
    },
    computed: {
      ...mapGetters(['activeTab']),
    },
    render(createElement) {
      return createElement('diffs-app', {
        props: {
          endpoint: this.endpoint,
          shouldShow: this.activeTab === 'diffs',
        },
      });
    },
  });
}
