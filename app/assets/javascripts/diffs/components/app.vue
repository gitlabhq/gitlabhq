<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { GlLoadingIcon, GlPagination, GlSprintf } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import Mousetrap from 'mousetrap';
import { __ } from '~/locale';
import { getParameterByName, parseBoolean } from '~/lib/utils/common_utils';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { isSingleViewStyle } from '~/helpers/diffs_helper';
import { updateHistory } from '~/lib/utils/url_utility';
import eventHub from '../../notes/event_hub';
import CompareVersions from './compare_versions.vue';
import DiffFile from './diff_file.vue';
import NoChanges from './no_changes.vue';
import CommitWidget from './commit_widget.vue';
import TreeList from './tree_list.vue';

import HiddenFilesWarning from './hidden_files_warning.vue';
import MergeConflictWarning from './merge_conflict_warning.vue';
import CollapsedFilesWarning from './collapsed_files_warning.vue';

import { diffsApp } from '../utils/performance';

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
} from '../constants';

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
  },
  mixins: [glFeatureFlagsMixin()],
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
    viewDiffsFileByFile: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    const treeWidth =
      parseInt(localStorage.getItem(TREE_LIST_WIDTH_STORAGE_KEY), 10) || INITIAL_TREE_WIDTH;

    return {
      treeWidth,
      diffFilesLength: 0,
    };
  },
  computed: {
    ...mapState({
      isLoading: state => state.diffs.isLoading,
      isBatchLoading: state => state.diffs.isBatchLoading,
      diffFiles: state => state.diffs.diffFiles,
      diffViewType: state => state.diffs.diffViewType,
      mergeRequestDiffs: state => state.diffs.mergeRequestDiffs,
      mergeRequestDiff: state => state.diffs.mergeRequestDiff,
      commit: state => state.diffs.commit,
      renderOverflowWarning: state => state.diffs.renderOverflowWarning,
      numTotalFiles: state => state.diffs.realSize,
      numVisibleFiles: state => state.diffs.size,
      plainDiffPath: state => state.diffs.plainDiffPath,
      emailPatchPath: state => state.diffs.emailPatchPath,
      retrievingBatches: state => state.diffs.retrievingBatches,
    }),
    ...mapState('diffs', [
      'showTreeList',
      'isLoading',
      'startVersion',
      'currentDiffFileId',
      'isTreeLoaded',
      'conflictResolutionPath',
      'canMerge',
      'hasConflicts',
    ]),
    ...mapGetters('diffs', ['whichCollapsedTypes', 'isParallelView', 'currentDiffIndex']),
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
      return (
        this.diffFiles.length > 0 ||
        (this.startVersion &&
          this.startVersion.version_index === this.mergeRequestDiff.version_index)
      );
    },
    hideFileStats() {
      return this.treeWidth <= TREE_HIDE_STATS_WIDTH;
    },
    isLimitedContainer() {
      return !this.showTreeList && !this.isParallelView && !this.isFluidLayout;
    },
    isDiffHead() {
      return parseBoolean(getParameterByName('diff_head'));
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
      } else if (this.isDiffHead && this.hasConflicts) {
        visible = this.$options.alerts.ALERT_MERGE_CONFLICT;
      } else if (this.whichCollapsedTypes.automatic && !this.viewDiffsFileByFile) {
        visible = this.$options.alerts.ALERT_COLLAPSED_FILES;
      }

      return visible;
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
    showTreeList: 'adjustView',
  },
  mounted() {
    this.setBaseConfig({
      endpoint: this.endpoint,
      endpointMetadata: this.endpointMetadata,
      endpointBatch: this.endpointBatch,
      endpointCoverage: this.endpointCoverage,
      projectPath: this.projectPath,
      dismissEndpoint: this.dismissEndpoint,
      showSuggestPopover: this.showSuggestPopover,
      viewDiffsFileByFile: this.viewDiffsFileByFile,
    });

    if (this.shouldShow) {
      this.fetchData();
    }

    const id = window?.location?.hash;

    if (id && id.indexOf('#note') !== 0) {
      this.setHighlightedRow(
        id
          .split('diff-content')
          .pop()
          .slice(1),
      );
    }
  },
  beforeCreate() {
    diffsApp.instrument();
  },
  created() {
    this.adjustView();

    eventHub.$once('fetchDiffData', this.fetchData);
    eventHub.$on('refetchDiffData', this.refetchDiffData);
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

    eventHub.$off('fetchDiffData', this.fetchData);
    eventHub.$off('refetchDiffData', this.refetchDiffData);
    this.removeEventListeners();
  },
  methods: {
    ...mapActions(['startTaskList']),
    ...mapActions('diffs', [
      'moveToNeighboringCommit',
      'setBaseConfig',
      'fetchDiffFilesMeta',
      'fetchDiffFilesBatch',
      'fetchCoverageFiles',
      'startRenderDiffsQueue',
      'assignDiscussionsToDiff',
      'setHighlightedRow',
      'cacheTreeListWidth',
      'scrollToFile',
      'setShowTreeList',
      'navigateToDiffFileIndex',
    ]),
    navigateToDiffFileNumber(number) {
      this.navigateToDiffFileIndex(number - 1);
    },
    refetchDiffData() {
      this.fetchData(false);
    },
    startDiffRendering() {
      requestIdleCallback(
        () => {
          this.startRenderDiffsQueue();
        },
        { timeout: 1000 },
      );
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

          this.startDiffRendering();
        })
        .catch(() => {
          createFlash(__('Something went wrong on our end. Please try again!'));
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
        .then(() => this.startDiffRendering())
        .catch(() => {
          createFlash(__('Something went wrong on our end. Please try again!'));
        });

      if (this.endpointCoverage) {
        this.fetchCoverageFiles();
      }

      if (!this.isNotesFetched) {
        eventHub.$emit('fetchNotesData');
      }
    },
    setDiscussions() {
      requestIdleCallback(
        () =>
          this.assignDiscussionsToDiff()
            .then(this.$nextTick)
            .then(this.startTaskList),
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
      Mousetrap.bind(['[', 'k', ']', 'j'], (e, combo) => {
        switch (combo) {
          case '[':
          case 'k':
            this.jumpToFile(-1);
            break;
          case ']':
          case 'j':
            this.jumpToFile(+1);
            break;
          default:
            break;
        }
      });

      if (this.commit && this.glFeatures.mrCommitNeighborNav) {
        Mousetrap.bind('c', () => this.moveToNeighboringCommit({ direction: 'next' }));
        Mousetrap.bind('x', () => this.moveToNeighboringCommit({ direction: 'previous' }));
      }
    },
    removeEventListeners() {
      Mousetrap.unbind(['[', 'k', ']', 'j']);
      Mousetrap.unbind('c');
      Mousetrap.unbind('x');
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
        :merge-request-diffs="mergeRequestDiffs"
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
          v-if="showTreeList"
          :style="{ width: `${treeWidth}px` }"
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
            <diff-file
              v-for="(file, index) in diffs"
              :key="file.newPath"
              :file="file"
              :is-first-file="index === 0"
              :is-last-file="index === diffs.length - 1"
              :help-page-path="helpPagePath"
              :can-current-user-fork="canCurrentUserFork"
              :view-diffs-file-by-file="viewDiffsFileByFile"
            />
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
          </template>
          <no-changes v-else :changes-empty-state-illustration="changesEmptyStateIllustration" />
        </div>
      </div>
    </div>
  </div>
</template>
