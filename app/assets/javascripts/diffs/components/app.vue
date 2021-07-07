<script>
import { GlLoadingIcon, GlPagination, GlSprintf } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import Mousetrap from 'mousetrap';
import { mapState, mapGetters, mapActions } from 'vuex';
import { DynamicScroller, DynamicScrollerItem } from 'vendor/vue-virtual-scroller';
import api from '~/api';
import {
  keysFor,
  MR_PREVIOUS_FILE_IN_DIFF,
  MR_NEXT_FILE_IN_DIFF,
  MR_COMMITS_NEXT_COMMIT,
  MR_COMMITS_PREVIOUS_COMMIT,
} from '~/behaviors/shortcuts/keybindings';
import createFlash from '~/flash';
import { isSingleViewStyle } from '~/helpers/diffs_helper';
import { parseBoolean } from '~/lib/utils/common_utils';
import { updateHistory } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';

import notesEventHub from '../../notes/event_hub';
import {
  TREE_LIST_WIDTH_STORAGE_KEY,
  INITIAL_TREE_WIDTH,
  MIN_TREE_WIDTH,
  MAX_TREE_WIDTH,
  TREE_HIDE_STATS_WIDTH,
  MR_TREE_SHOW_KEY,
  CENTERED_LIMITED_CONTAINER_CLASSES,
  ALERT_OVERFLOW_HIDDEN,
  ALERT_MERGE_CONFLICT,
  ALERT_COLLAPSED_FILES,
  INLINE_DIFF_VIEW_TYPE,
  TRACKING_DIFF_VIEW_INLINE,
  TRACKING_DIFF_VIEW_PARALLEL,
  TRACKING_FILE_BROWSER_TREE,
  TRACKING_FILE_BROWSER_LIST,
  TRACKING_WHITESPACE_SHOW,
  TRACKING_WHITESPACE_HIDE,
  TRACKING_SINGLE_FILE_MODE,
  TRACKING_MULTIPLE_FILES_MODE,
} from '../constants';

import diffsEventHub from '../event_hub';
import { reviewStatuses } from '../utils/file_reviews';
import { diffsApp } from '../utils/performance';
import { fileByFile } from '../utils/preferences';
import CollapsedFilesWarning from './collapsed_files_warning.vue';
import CommitWidget from './commit_widget.vue';
import CompareVersions from './compare_versions.vue';
import DiffFile from './diff_file.vue';
import HiddenFilesWarning from './hidden_files_warning.vue';
import MergeConflictWarning from './merge_conflict_warning.vue';
import NoChanges from './no_changes.vue';
import PreRenderer from './pre_renderer.vue';
import TreeList from './tree_list.vue';
import VirtualScrollerScrollSync from './virtual_scroller_scroll_sync';

export default {
  name: 'DiffsApp',
  components: {
    CompareVersions,
    DiffFile,
    NoChanges,
    HiddenFilesWarning,
    MergeConflictWarning,
    CollapsedFilesWarning,
    CommitWidget,
    TreeList,
    GlLoadingIcon,
    PanelResizer,
    GlPagination,
    GlSprintf,
    DynamicScroller,
    DynamicScrollerItem,
    PreRenderer,
    VirtualScrollerScrollSync,
  },
  alerts: {
    ALERT_OVERFLOW_HIDDEN,
    ALERT_MERGE_CONFLICT,
    ALERT_COLLAPSED_FILES,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    endpointMetadata: {
      type: String,
      required: true,
    },
    endpointBatch: {
      type: String,
      required: true,
    },
    endpointCoverage: {
      type: String,
      required: false,
      default: '',
    },
    endpointCodequality: {
      type: String,
      required: false,
      default: '',
    },
    endpointUpdateUser: {
      type: String,
      required: false,
      default: '',
    },
    projectPath: {
      type: String,
      required: true,
    },
    shouldShow: {
      type: Boolean,
      required: false,
      default: false,
    },
    currentUser: {
      type: Object,
      required: true,
    },
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
    changesEmptyStateIllustration: {
      type: String,
      required: false,
      default: '',
    },
    isFluidLayout: {
      type: Boolean,
      required: false,
      default: false,
    },
    dismissEndpoint: {
      type: String,
      required: false,
      default: '',
    },
    showSuggestPopover: {
      type: Boolean,
      required: false,
      default: false,
    },
    fileByFileUserPreference: {
      type: Boolean,
      required: false,
      default: false,
    },
    defaultSuggestionCommitMessage: {
      type: String,
      required: false,
      default: '',
    },
    rehydratedMrReviews: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    const treeWidth =
      parseInt(localStorage.getItem(TREE_LIST_WIDTH_STORAGE_KEY), 10) || INITIAL_TREE_WIDTH;

    return {
      treeWidth,
      diffFilesLength: 0,
      virtualScrollCurrentIndex: -1,
    };
  },
  computed: {
    ...mapState({
      isLoading: (state) => state.diffs.isLoading,
      isBatchLoading: (state) => state.diffs.isBatchLoading,
      diffFiles: (state) => state.diffs.diffFiles,
      diffViewType: (state) => state.diffs.diffViewType,
      commit: (state) => state.diffs.commit,
      renderOverflowWarning: (state) => state.diffs.renderOverflowWarning,
      numTotalFiles: (state) => state.diffs.realSize,
      numVisibleFiles: (state) => state.diffs.size,
      plainDiffPath: (state) => state.diffs.plainDiffPath,
      emailPatchPath: (state) => state.diffs.emailPatchPath,
      retrievingBatches: (state) => state.diffs.retrievingBatches,
    }),
    ...mapState('diffs', [
      'showTreeList',
      'isLoading',
      'startVersion',
      'latestDiff',
      'currentDiffFileId',
      'isTreeLoaded',
      'conflictResolutionPath',
      'canMerge',
      'hasConflicts',
      'viewDiffsFileByFile',
      'mrReviews',
      'renderTreeList',
      'showWhitespace',
    ]),
    ...mapGetters('diffs', [
      'whichCollapsedTypes',
      'isParallelView',
      'currentDiffIndex',
      'isVirtualScrollingEnabled',
    ]),
    ...mapGetters('batchComments', ['draftsCount']),
    ...mapGetters(['isNotesFetched', 'getNoteableData']),
    diffs() {
      if (!this.viewDiffsFileByFile) {
        return this.diffFiles;
      }

      return this.diffFiles.filter((file, i) => {
        return file.file_hash === this.currentDiffFileId || (i === 0 && !this.currentDiffFileId);
      });
    },
    canCurrentUserFork() {
      return this.currentUser.can_fork === true && this.currentUser.can_create_merge_request;
    },
    renderDiffFiles() {
      return this.diffFiles.length > 0;
    },
    renderFileTree() {
      return this.renderDiffFiles && this.showTreeList;
    },
    hideFileStats() {
      return this.treeWidth <= TREE_HIDE_STATS_WIDTH;
    },
    isLimitedContainer() {
      return !this.renderFileTree && !this.isParallelView && !this.isFluidLayout;
    },
    isFullChangeset() {
      return this.startVersion === null && this.latestDiff;
    },
    showFileByFileNavigation() {
      return this.diffFiles.length > 1 && this.viewDiffsFileByFile;
    },
    currentFileNumber() {
      return this.currentDiffIndex + 1;
    },
    previousFileNumber() {
      const { currentDiffIndex } = this;

      return currentDiffIndex >= 1 ? currentDiffIndex : null;
    },
    nextFileNumber() {
      const { currentFileNumber, diffFiles } = this;

      return currentFileNumber < diffFiles.length ? currentFileNumber + 1 : null;
    },
    visibleWarning() {
      let visible = false;

      if (this.renderOverflowWarning) {
        visible = this.$options.alerts.ALERT_OVERFLOW_HIDDEN;
      } else if (this.isFullChangeset && this.hasConflicts) {
        visible = this.$options.alerts.ALERT_MERGE_CONFLICT;
      } else if (this.whichCollapsedTypes.automatic && !this.viewDiffsFileByFile) {
        visible = this.$options.alerts.ALERT_COLLAPSED_FILES;
      }

      return visible;
    },
    fileReviews() {
      return reviewStatuses(this.diffFiles, this.mrReviews);
    },
  },
  watch: {
    commit(newCommit, oldCommit) {
      const commitChangedAfterRender = newCommit && !this.isLoading;
      const commitIsDifferent = oldCommit && newCommit.id !== oldCommit.id;
      const url = window?.location ? String(window.location) : '';

      if (commitChangedAfterRender && commitIsDifferent) {
        updateHistory({
          title: document.title,
          url: url.replace(oldCommit.id, newCommit.id),
        });
        this.refetchDiffData();
        this.adjustView();
      }
    },
    diffViewType() {
      this.adjustView();
    },
    shouldShow() {
      // When the shouldShow property changed to true, the route is rendered for the first time
      // and if we have the isLoading as true this means we didn't fetch the data
      if (this.isLoading) {
        this.fetchData();
      }

      this.adjustView();
    },
    isLoading: 'adjustView',
    renderFileTree: 'adjustView',
  },
  mounted() {
    this.setBaseConfig({
      endpoint: this.endpoint,
      endpointMetadata: this.endpointMetadata,
      endpointBatch: this.endpointBatch,
      endpointCoverage: this.endpointCoverage,
      endpointUpdateUser: this.endpointUpdateUser,
      projectPath: this.projectPath,
      dismissEndpoint: this.dismissEndpoint,
      showSuggestPopover: this.showSuggestPopover,
      viewDiffsFileByFile: fileByFile(this.fileByFileUserPreference),
      defaultSuggestionCommitMessage: this.defaultSuggestionCommitMessage,
      mrReviews: this.rehydratedMrReviews,
    });

    if (this.endpointCodequality) {
      this.setCodequalityEndpoint(this.endpointCodequality);
    }

    if (this.shouldShow) {
      this.fetchData();
    }

    const id = window?.location?.hash;

    if (id && id.indexOf('#note') !== 0) {
      this.setHighlightedRow(id.split('diff-content').pop().slice(1));
    }

    if (window.gon?.features?.diffsVirtualScrolling) {
      diffsEventHub.$on('scrollToFileHash', this.scrollVirtualScrollerToFileHash);
      diffsEventHub.$on('scrollToIndex', this.scrollVirtualScrollerToIndex);
    }

    if (window.gon?.features?.diffSettingsUsageData) {
      if (this.renderTreeList) {
        api.trackRedisHllUserEvent(TRACKING_FILE_BROWSER_TREE);
      } else {
        api.trackRedisHllUserEvent(TRACKING_FILE_BROWSER_LIST);
      }

      if (this.diffViewType === INLINE_DIFF_VIEW_TYPE) {
        api.trackRedisHllUserEvent(TRACKING_DIFF_VIEW_INLINE);
      } else {
        api.trackRedisHllUserEvent(TRACKING_DIFF_VIEW_PARALLEL);
      }

      if (this.showWhitespace) {
        api.trackRedisHllUserEvent(TRACKING_WHITESPACE_SHOW);
      } else {
        api.trackRedisHllUserEvent(TRACKING_WHITESPACE_HIDE);
      }

      if (this.viewDiffsFileByFile) {
        api.trackRedisHllUserEvent(TRACKING_SINGLE_FILE_MODE);
      } else {
        api.trackRedisHllUserEvent(TRACKING_MULTIPLE_FILES_MODE);
      }
    }
  },
  beforeCreate() {
    diffsApp.instrument();
  },
  created() {
    this.adjustView();
    this.subscribeToEvents();

    this.CENTERED_LIMITED_CONTAINER_CLASSES = CENTERED_LIMITED_CONTAINER_CLASSES;

    this.unwatchDiscussions = this.$watch(
      () => `${this.diffFiles.length}:${this.$store.state.notes.discussions.length}`,
      () => this.setDiscussions(),
    );

    this.unwatchRetrievingBatches = this.$watch(
      () => `${this.retrievingBatches}:${this.$store.state.notes.discussions.length}`,
      () => {
        if (!this.retrievingBatches && this.$store.state.notes.discussions.length) {
          this.unwatchDiscussions();
          this.unwatchRetrievingBatches();
        }
      },
    );
  },
  beforeDestroy() {
    diffsApp.deinstrument();
    this.unsubscribeFromEvents();
    this.removeEventListeners();

    if (window.gon?.features?.diffsVirtualScrolling) {
      diffsEventHub.$off('scrollToFileHash', this.scrollVirtualScrollerToFileHash);
      diffsEventHub.$off('scrollToIndex', this.scrollVirtualScrollerToIndex);
    }
  },
  methods: {
    ...mapActions(['startTaskList']),
    ...mapActions('diffs', [
      'moveToNeighboringCommit',
      'setBaseConfig',
      'setCodequalityEndpoint',
      'fetchDiffFilesMeta',
      'fetchDiffFilesBatch',
      'fetchCoverageFiles',
      'fetchCodequality',
      'startRenderDiffsQueue',
      'assignDiscussionsToDiff',
      'setHighlightedRow',
      'cacheTreeListWidth',
      'scrollToFile',
      'setShowTreeList',
      'navigateToDiffFileIndex',
      'setFileByFile',
    ]),
    subscribeToEvents() {
      notesEventHub.$once('fetchDiffData', this.fetchData);
      notesEventHub.$on('refetchDiffData', this.refetchDiffData);
    },
    unsubscribeFromEvents() {
      notesEventHub.$off('refetchDiffData', this.refetchDiffData);
      notesEventHub.$off('fetchDiffData', this.fetchData);
    },
    navigateToDiffFileNumber(number) {
      this.navigateToDiffFileIndex(number - 1);
    },
    refetchDiffData() {
      this.fetchData(false);
    },
    needsReload() {
      return this.diffFiles.length && isSingleViewStyle(this.diffFiles[0]);
    },
    needsFirstLoad() {
      return !this.diffFiles.length;
    },
    fetchData(toggleTree = true) {
      this.fetchDiffFilesMeta()
        .then(({ real_size }) => {
          this.diffFilesLength = parseInt(real_size, 10);
          if (toggleTree) this.setTreeDisplay();
        })
        .catch(() => {
          createFlash({
            message: __('Something went wrong on our end. Please try again!'),
          });
        });

      this.fetchDiffFilesBatch()
        .then(() => {
          if (toggleTree) this.setTreeDisplay();
          // Guarantee the discussions are assigned after the batch finishes.
          // Just watching the length of the discussions or the diff files
          // isn't enough, because with split diff loading, neither will
          // change when loading the other half of the diff files.
          this.setDiscussions();
        })
        .catch(() => {
          createFlash({
            message: __('Something went wrong on our end. Please try again!'),
          });
        });

      if (this.endpointCoverage) {
        this.fetchCoverageFiles();
      }

      if (this.endpointCodequality) {
        this.fetchCodequality();
      }

      if (!this.isNotesFetched) {
        notesEventHub.$emit('fetchNotesData');
      }
    },
    setDiscussions() {
      requestIdleCallback(
        () =>
          this.assignDiscussionsToDiff()
            .then(this.$nextTick)
            .then(this.startTaskList)
            .then(this.scrollVirtualScrollerToDiffNote),
        { timeout: 1000 },
      );
    },
    adjustView() {
      if (this.shouldShow) {
        this.$nextTick(() => {
          this.setEventListeners();
        });
      } else {
        this.removeEventListeners();
      }
    },
    setEventListeners() {
      Mousetrap.bind(keysFor(MR_PREVIOUS_FILE_IN_DIFF), () => this.jumpToFile(-1));
      Mousetrap.bind(keysFor(MR_NEXT_FILE_IN_DIFF), () => this.jumpToFile(+1));

      if (this.commit) {
        Mousetrap.bind(keysFor(MR_COMMITS_NEXT_COMMIT), () =>
          this.moveToNeighboringCommit({ direction: 'next' }),
        );
        Mousetrap.bind(keysFor(MR_COMMITS_PREVIOUS_COMMIT), () =>
          this.moveToNeighboringCommit({ direction: 'previous' }),
        );
      }
    },
    removeEventListeners() {
      Mousetrap.unbind(keysFor(MR_PREVIOUS_FILE_IN_DIFF));
      Mousetrap.unbind(keysFor(MR_NEXT_FILE_IN_DIFF));
      Mousetrap.unbind(keysFor(MR_COMMITS_NEXT_COMMIT));
      Mousetrap.unbind(keysFor(MR_COMMITS_PREVIOUS_COMMIT));
    },
    jumpToFile(step) {
      const targetIndex = this.currentDiffIndex + step;
      if (targetIndex >= 0 && targetIndex < this.diffFiles.length) {
        this.scrollToFile(this.diffFiles[targetIndex].file_path);
      }
    },
    setTreeDisplay() {
      const storedTreeShow = localStorage.getItem(MR_TREE_SHOW_KEY);
      let showTreeList = true;

      if (storedTreeShow !== null) {
        showTreeList = parseBoolean(storedTreeShow);
      } else if (!bp.isDesktop() || (!this.isBatchLoading && this.diffFiles.length <= 1)) {
        showTreeList = false;
      }

      return this.setShowTreeList({ showTreeList, saving: false });
    },
    async scrollVirtualScrollerToFileHash(hash) {
      const index = this.diffFiles.findIndex((f) => f.file_hash === hash);

      if (index !== -1) {
        this.scrollVirtualScrollerToIndex(index);
      }
    },
    async scrollVirtualScrollerToIndex(index) {
      this.virtualScrollCurrentIndex = index;

      await this.$nextTick();

      this.virtualScrollCurrentIndex = -1;
    },
    scrollVirtualScrollerToDiffNote() {
      if (!window.gon?.features?.diffsVirtualScrolling) return;

      const id = window?.location?.hash;

      if (id.startsWith('#note_')) {
        const noteId = id.replace('#note_', '');
        const discussion = this.$store.state.notes.discussions.find(
          (d) => d.diff_file && d.notes.find((n) => n.id === noteId),
        );

        if (discussion) {
          this.scrollVirtualScrollerToFileHash(discussion.diff_file.file_hash);
        }
      }
    },
  },
  minTreeWidth: MIN_TREE_WIDTH,
  maxTreeWidth: MAX_TREE_WIDTH,
};
</script>

<template>
  <div v-show="shouldShow">
    <div v-if="isLoading || !isTreeLoaded" class="loading"><gl-loading-icon size="lg" /></div>
    <div v-else id="diffs" :class="{ active: shouldShow }" class="diffs tab-pane">
      <compare-versions
        :is-limited-container="isLimitedContainer"
        :diff-files-count-text="numTotalFiles"
      />

      <hidden-files-warning
        v-if="visibleWarning == $options.alerts.ALERT_OVERFLOW_HIDDEN"
        :visible="numVisibleFiles"
        :total="numTotalFiles"
        :plain-diff-path="plainDiffPath"
        :email-patch-path="emailPatchPath"
      />
      <merge-conflict-warning
        v-if="visibleWarning == $options.alerts.ALERT_MERGE_CONFLICT"
        :limited="isLimitedContainer"
        :resolution-path="conflictResolutionPath"
        :mergeable="canMerge"
      />
      <collapsed-files-warning
        v-if="visibleWarning == $options.alerts.ALERT_COLLAPSED_FILES"
        :limited="isLimitedContainer"
      />

      <div
        :data-can-create-note="getNoteableData.current_user.can_create_note"
        class="files d-flex gl-mt-2"
      >
        <div
          v-if="renderFileTree"
          :style="{ width: `${treeWidth}px` }"
          :class="{ 'review-bar-visible': draftsCount > 0 }"
          class="diff-tree-list js-diff-tree-list px-3 pr-md-0"
        >
          <panel-resizer
            :size.sync="treeWidth"
            :start-size="treeWidth"
            :min-size="$options.minTreeWidth"
            :max-size="$options.maxTreeWidth"
            side="right"
            @resize-end="cacheTreeListWidth"
          />
          <tree-list :hide-file-stats="hideFileStats" />
        </div>
        <div
          class="col-12 col-md-auto diff-files-holder"
          :class="{
            [CENTERED_LIMITED_CONTAINER_CLASSES]: isLimitedContainer,
          }"
        >
          <commit-widget v-if="commit" :commit="commit" :collapsible="false" />
          <div v-if="isBatchLoading" class="loading"><gl-loading-icon size="lg" /></div>
          <template v-else-if="renderDiffFiles">
            <dynamic-scroller
              v-if="isVirtualScrollingEnabled"
              ref="virtualScroller"
              :items="diffs"
              :min-item-size="70"
              :buffer="1000"
              :use-transform="false"
              page-mode
            >
              <template #default="{ item, index, active }">
                <dynamic-scroller-item :item="item" :active="active" :class="{ active }">
                  <diff-file
                    :file="item"
                    :reviewed="fileReviews[item.id]"
                    :is-first-file="index === 0"
                    :is-last-file="index === diffFilesLength - 1"
                    :help-page-path="helpPagePath"
                    :can-current-user-fork="canCurrentUserFork"
                    :view-diffs-file-by-file="viewDiffsFileByFile"
                    :active="active"
                  />
                </dynamic-scroller-item>
              </template>
              <template #before>
                <pre-renderer :max-length="diffFilesLength">
                  <template #default="{ item, index, active }">
                    <dynamic-scroller-item :item="item" :active="active">
                      <diff-file
                        :file="item"
                        :reviewed="fileReviews[item.id]"
                        :is-first-file="index === 0"
                        :is-last-file="index === diffFilesLength - 1"
                        :help-page-path="helpPagePath"
                        :can-current-user-fork="canCurrentUserFork"
                        :view-diffs-file-by-file="viewDiffsFileByFile"
                        pre-render
                      />
                    </dynamic-scroller-item>
                  </template>
                </pre-renderer>
                <virtual-scroller-scroll-sync :index="virtualScrollCurrentIndex" />
              </template>
            </dynamic-scroller>
            <template v-else>
              <diff-file
                v-for="(file, index) in diffs"
                :key="file.new_path"
                :file="file"
                :reviewed="fileReviews[file.id]"
                :is-first-file="index === 0"
                :is-last-file="index === diffFilesLength - 1"
                :help-page-path="helpPagePath"
                :can-current-user-fork="canCurrentUserFork"
                :view-diffs-file-by-file="viewDiffsFileByFile"
              />
            </template>
            <div
              v-if="showFileByFileNavigation"
              data-testid="file-by-file-navigation"
              class="gl-display-grid gl-text-center"
            >
              <gl-pagination
                class="gl-mx-auto"
                :value="currentFileNumber"
                :prev-page="previousFileNumber"
                :next-page="nextFileNumber"
                @input="navigateToDiffFileNumber"
              />
              <gl-sprintf :message="__('File %{current} of %{total}')">
                <template #current>{{ currentFileNumber }}</template>
                <template #total>{{ diffFiles.length }}</template>
              </gl-sprintf>
            </div>
            <gl-loading-icon v-else-if="retrievingBatches" size="lg" />
          </template>
          <no-changes v-else :changes-empty-state-illustration="changesEmptyStateIllustration" />
        </div>
      </div>
    </div>
  </div>
</template>
