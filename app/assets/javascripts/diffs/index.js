import Vue from 'vue';
import { mapActions, mapState, mapGetters } from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import { getParameterValues } from '~/lib/utils/url_utility';
import FindFile from '~/vue_shared/components/file_finder/index.vue';
import eventHub from '../notes/event_hub';
import diffsApp from './components/app.vue';
import { TREE_LIST_STORAGE_KEY } from './constants';

export default function initDiffsApp(store) {
  const fileFinderEl = document.getElementById('js-diff-file-finder');

  if (fileFinderEl) {
    // eslint-disable-next-line no-new
    new Vue({
      el: fileFinderEl,
      store,
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
          this.scrollToFile(file.path);
        },
      },
      render(createElement) {
        return createElement(FindFile, {
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
          style: {
            display: this.fileFinderVisible ? '' : 'none',
          },
        });
      },
    });
  }

  return new Vue({
    el: '#js-diffs-app',
    name: 'MergeRequestDiffs',
    components: {
      diffsApp,
    },
    store,
    data() {
      const { dataset } = document.querySelector(this.$options.el);

      return {
        endpoint: dataset.endpoint,
        endpointMetadata: dataset.endpointMetadata || '',
        endpointBatch: dataset.endpointBatch || '',
        projectPath: dataset.projectPath,
        helpPagePath: dataset.helpPagePath,
        currentUser: JSON.parse(dataset.currentUserData) || {},
        changesEmptyStateIllustration: dataset.changesEmptyStateIllustration,
        isFluidLayout: parseBoolean(dataset.isFluidLayout),
        dismissEndpoint: dataset.dismissEndpoint,
        showSuggestPopover: parseBoolean(dataset.showSuggestPopover),
        showWhitespaceDefault: parseBoolean(dataset.showWhitespaceDefault),
      };
    },
    computed: {
      ...mapState({
        activeTab: state => state.page.activeTab,
      }),
    },
    created() {
      let hideWhitespace = getParameterValues('w')[0];
      const treeListStored = localStorage.getItem(TREE_LIST_STORAGE_KEY);
      const renderTreeList = treeListStored !== null ? parseBoolean(treeListStored) : true;

      this.setRenderTreeList(renderTreeList);
      if (!hideWhitespace) {
        hideWhitespace = this.showWhitespaceDefault ? '0' : '1';
      }
      this.setShowWhitespace({ showWhitespace: hideWhitespace !== '1' });
    },
    methods: {
      ...mapActions('diffs', ['setRenderTreeList', 'setShowWhitespace']),
    },
    render(createElement) {
      return createElement('diffs-app', {
        props: {
          endpoint: this.endpoint,
          endpointMetadata: this.endpointMetadata,
          endpointBatch: this.endpointBatch,
          currentUser: this.currentUser,
          projectPath: this.projectPath,
          helpPagePath: this.helpPagePath,
          shouldShow: this.activeTab === 'diffs',
          changesEmptyStateIllustration: this.changesEmptyStateIllustration,
          isFluidLayout: this.isFluidLayout,
          dismissEndpoint: this.dismissEndpoint,
          showSuggestPopover: this.showSuggestPopover,
          showWhitespaceDefault: this.showWhitespaceDefault,
        },
      });
    },
  });
}
