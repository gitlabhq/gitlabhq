import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mapActions, mapState, mapGetters } from 'vuex';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { getCookie, parseBoolean, removeCookie } from '~/lib/utils/common_utils';
import notesStore from '~/mr_notes/stores';

import eventHub from '../notes/event_hub';
import DiffsApp from './components/app.vue';

import { TREE_LIST_STORAGE_KEY, DIFF_WHITESPACE_COOKIE_NAME } from './constants';
import { getReviewsForMergeRequest } from './utils/file_reviews';
import { getDerivedMergeRequestInformation } from './utils/merge_request';

export default function initDiffsApp(store = notesStore) {
  const el = document.getElementById('js-diffs-app');
  const { dataset } = el;

  Vue.use(VueApollo);

  const vm = new Vue({
    el,
    name: 'MergeRequestDiffs',
    components: {
      DiffsApp,
    },
    store,
    apolloProvider,
    provide: {
      newCommentTemplatePath: dataset.newCommentTemplatePath,
      showGenerateTestFileButton: parseBoolean(dataset.showGenerateTestFileButton),
    },
    data() {
      return {
        endpoint: dataset.endpoint,
        endpointMetadata: dataset.endpointMetadata || '',
        endpointBatch: dataset.endpointBatch || '',
        endpointDiffForPath: dataset.endpointDiffForPath || '',
        endpointCoverage: dataset.endpointCoverage || '',
        endpointCodequality: dataset.endpointCodequality || '',
        endpointUpdateUser: dataset.updateCurrentUserPath,
        projectPath: dataset.projectPath,
        helpPagePath: dataset.helpPagePath,
        currentUser: JSON.parse(dataset.currentUserData) || {},
        changesEmptyStateIllustration: dataset.changesEmptyStateIllustration,
        isFluidLayout: parseBoolean(dataset.isFluidLayout),
        dismissEndpoint: dataset.dismissEndpoint,
        showSuggestPopover: parseBoolean(dataset.showSuggestPopover),
        showWhitespaceDefault: parseBoolean(dataset.showWhitespaceDefault),
        viewDiffsFileByFile: parseBoolean(dataset.fileByFileDefault),
        defaultSuggestionCommitMessage: dataset.defaultSuggestionCommitMessage,
        sourceProjectDefaultUrl: dataset.sourceProjectDefaultUrl,
        sourceProjectFullPath: dataset.sourceProjectFullPath,
        isForked: parseBoolean(dataset.isForked),
      };
    },
    computed: {
      ...mapState({
        activeTab: (state) => state.page.activeTab,
      }),
    },
    created() {
      const treeListStored = localStorage.getItem(TREE_LIST_STORAGE_KEY);
      const renderTreeList = treeListStored !== null ? parseBoolean(treeListStored) : true;

      this.setRenderTreeList({ renderTreeList, trackClick: false });

      // NOTE: A "true" or "checked" value for `showWhitespace` is '0' not '1'.
      // Check for cookie and save that setting for future use.
      // Then delete the cookie as we are phasing it out and using the database as SSOT.
      // NOTE: This can/should be removed later
      if (getCookie(DIFF_WHITESPACE_COOKIE_NAME)) {
        const hideWhitespace = getCookie(DIFF_WHITESPACE_COOKIE_NAME);
        this.setShowWhitespace({
          url: this.endpointUpdateUser,
          showWhitespace: hideWhitespace !== '1',
          trackClick: false,
        });
        removeCookie(DIFF_WHITESPACE_COOKIE_NAME);
      } else {
        // This is only to set the the user preference in Vuex for use later
        this.setShowWhitespace({
          showWhitespace: this.showWhitespaceDefault,
          updateDatabase: false,
          trackClick: false,
        });
      }
    },
    methods: {
      ...mapActions('diffs', ['setRenderTreeList', 'setShowWhitespace']),
    },
    render(createElement) {
      const { mrPath } = getDerivedMergeRequestInformation({ endpoint: this.endpoint });

      return createElement('diffs-app', {
        props: {
          endpoint: this.endpoint,
          endpointMetadata: this.endpointMetadata,
          endpointBatch: this.endpointBatch,
          endpointDiffForPath: this.endpointDiffForPath,
          endpointCoverage: this.endpointCoverage,
          endpointCodequality: this.endpointCodequality,
          endpointUpdateUser: this.endpointUpdateUser,
          currentUser: this.currentUser,
          projectPath: this.projectPath,
          helpPagePath: this.helpPagePath,
          shouldShow: this.activeTab === 'diffs',
          changesEmptyStateIllustration: this.changesEmptyStateIllustration,
          isFluidLayout: this.isFluidLayout,
          dismissEndpoint: this.dismissEndpoint,
          showSuggestPopover: this.showSuggestPopover,
          fileByFileUserPreference: this.viewDiffsFileByFile,
          defaultSuggestionCommitMessage: this.defaultSuggestionCommitMessage,
          rehydratedMrReviews: getReviewsForMergeRequest(mrPath),
          sourceProjectDefaultUrl: this.sourceProjectDefaultUrl,
          sourceProjectFullPath: this.sourceProjectFullPath,
          isForked: this.isForked,
        },
      });
    },
  });

  const fileFinderEl = document.getElementById('js-diff-file-finder');

  if (fileFinderEl) {
    // eslint-disable-next-line no-new
    new Vue({
      el: fileFinderEl,
      store,
      components: {
        FindFile: () => import('~/vue_shared/components/file_finder/index.vue'),
      },
      computed: {
        ...mapState('diffs', ['fileFinderVisible', 'isLoading']),
        ...mapGetters('diffs', ['flatBlobsList']),
      },
      watch: {
        fileFinderVisible(newVal, oldVal) {
          if (newVal && !oldVal && !this.flatBlobsList.length) {
            eventHub.$emit('fetchDiffData');
          }
        },
      },
      methods: {
        ...mapActions('diffs', ['toggleFileFinder', 'scrollToFile']),
        openFile(file) {
          window.mrTabs.tabShown('diffs');
          this.scrollToFile({ path: file.path });
        },
      },
      render(createElement) {
        return createElement('find-file', {
          props: {
            files: this.flatBlobsList,
            visible: this.fileFinderVisible,
            loading: this.isLoading,
            showDiffStats: true,
            clearSearchOnClose: false,
          },
          on: {
            toggle: this.toggleFileFinder,
            click: this.openFile,
          },
          class: ['diff-file-finder'],
        });
      },
    });
  }

  return vm;
}
