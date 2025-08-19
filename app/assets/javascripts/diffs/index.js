import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mapActions, mapState } from 'pinia';
import { GlToast } from '@gitlab/ui';
import { cleanLeadingSeparator } from '~/lib/utils/url_utility';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { getCookie, parseBoolean, removeCookie } from '~/lib/utils/common_utils';
import { pinia } from '~/pinia/instance';
import { useMrNotes } from '~/mr_notes/store/legacy_mr_notes';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import eventHub from '../notes/event_hub';
import DiffsApp from './components/app.vue';
import { TREE_LIST_STORAGE_KEY, DIFF_WHITESPACE_COOKIE_NAME } from './constants';

export default function initDiffsApp() {
  const el = document.getElementById('js-diffs-app');
  const { dataset } = el;

  Vue.use(VueApollo);
  Vue.use(GlToast);
  const { newCommentTemplatePaths } = dataset;

  const vm = new Vue({
    el,
    name: 'MergeRequestDiffs',
    components: {
      DiffsApp,
    },
    pinia,
    apolloProvider,
    provide: {
      newCommentTemplatePaths: newCommentTemplatePaths ? JSON.parse(newCommentTemplatePaths) : [],
    },
    data() {
      return {
        projectPath: dataset.projectPath || '',
        iid: dataset.iid || '',
        endpointCoverage: dataset.endpointCoverage || '',
        codequalityReportAvailable: parseBoolean(dataset.codequalityReportAvailable),
        sastReportAvailable: parseBoolean(dataset.sastReportAvailable),
        helpPagePath: dataset.helpPagePath,
        currentUser: JSON.parse(dataset.currentUserData) || {},
        changesEmptyStateIllustration: dataset.changesEmptyStateIllustration,
        dismissEndpoint: dataset.dismissEndpoint,
        showWhitespaceDefault: parseBoolean(dataset.showWhitespaceDefault),
      };
    },
    computed: {
      ...mapState(useMrNotes, ['activeTab']),
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
        // This is only to set the user preference in Vuex for use later
        this.setShowWhitespace({
          showWhitespace: this.showWhitespaceDefault,
          updateDatabase: false,
          trackClick: false,
        });
      }
    },
    methods: {
      ...mapActions(useLegacyDiffs, ['setRenderTreeList', 'setShowWhitespace']),
    },
    render(createElement) {
      return createElement('diffs-app', {
        props: {
          projectPath: cleanLeadingSeparator(this.projectPath),
          iid: this.iid,
          endpointCoverage: this.endpointCoverage,
          endpointCodequality: this.endpointCodequality,
          codequalityReportAvailable: this.codequalityReportAvailable,
          sastReportAvailable: this.sastReportAvailable,
          currentUser: this.currentUser,
          helpPagePath: this.helpPagePath,
          shouldShow: this.activeTab === 'diffs',
          changesEmptyStateIllustration: this.changesEmptyStateIllustration,
          linkedFileUrl: dataset.linkedFileUrl,
        },
      });
    },
  });

  const fileFinderEl = document.getElementById('js-diff-file-finder');

  if (fileFinderEl) {
    // eslint-disable-next-line no-new
    new Vue({
      el: fileFinderEl,
      pinia,
      components: {
        FindFile: () => import('~/vue_shared/components/file_finder/index.vue'),
      },
      computed: {
        ...mapState(useLegacyDiffs, ['fileFinderVisible', 'isLoading', 'flatBlobsList']),
      },
      watch: {
        fileFinderVisible(newVal, oldVal) {
          if (newVal && !oldVal && !this.flatBlobsList.length) {
            eventHub.$emit('fetchDiffData');
          }
        },
      },
      methods: {
        ...mapActions(useLegacyDiffs, ['toggleFileFinder', 'scrollToFile']),
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
