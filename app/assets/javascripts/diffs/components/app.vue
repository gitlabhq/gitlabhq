<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import Icon from '~/vue_shared/components/icon.vue';
import { __ } from '~/locale';
import createFlash from '~/flash';
import { GlLoadingIcon } from '@gitlab/ui';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';
import Mousetrap from 'mousetrap';
import eventHub from '../../notes/event_hub';
import CompareVersions from './compare_versions.vue';
import DiffFile from './diff_file.vue';
import NoChanges from './no_changes.vue';
import HiddenFilesWarning from './hidden_files_warning.vue';
import CommitWidget from './commit_widget.vue';
import TreeList from './tree_list.vue';
import {
  TREE_LIST_WIDTH_STORAGE_KEY,
  INITIAL_TREE_WIDTH,
  MIN_TREE_WIDTH,
  MAX_TREE_WIDTH,
  TREE_HIDE_STATS_WIDTH,
  MR_TREE_SHOW_KEY,
  CENTERED_LIMITED_CONTAINER_CLASSES,
} from '../constants';

export default {
  name: 'DiffsApp',
  components: {
    Icon,
    CompareVersions,
    DiffFile,
    NoChanges,
    HiddenFilesWarning,
    CommitWidget,
    TreeList,
    GlLoadingIcon,
    PanelResizer,
  },
  mixins: [glFeatureFlagsMixin()],
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
  },
  data() {
    const treeWidth =
      parseInt(localStorage.getItem(TREE_LIST_WIDTH_STORAGE_KEY), 10) || INITIAL_TREE_WIDTH;

    return {
      assignedDiscussions: false,
      treeWidth,
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
      targetBranchName: state => state.diffs.targetBranchName,
      renderOverflowWarning: state => state.diffs.renderOverflowWarning,
      numTotalFiles: state => state.diffs.realSize,
      numVisibleFiles: state => state.diffs.size,
      plainDiffPath: state => state.diffs.plainDiffPath,
      emailPatchPath: state => state.diffs.emailPatchPath,
    }),
    ...mapState('diffs', ['showTreeList', 'isLoading', 'startVersion']),
    ...mapGetters('diffs', ['isParallelView', 'currentDiffIndex']),
    ...mapGetters(['isNotesFetched', 'getNoteableData']),
    targetBranch() {
      return {
        branchName: this.targetBranchName,
        versionIndex: -1,
        path: '',
      };
    },
    canCurrentUserFork() {
      return this.currentUser.can_fork === true && this.currentUser.can_create_merge_request;
    },
    showCompareVersions() {
      return this.mergeRequestDiffs && this.mergeRequestDiff;
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
    shouldSetDiscussions() {
      return this.isNotesFetched && !this.assignedDiscussions && !this.isLoading;
    },
  },
  watch: {
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
    shouldSetDiscussions(newVal) {
      if (newVal) {
        this.setDiscussions();
      }
    },
  },
  mounted() {
    this.setBaseConfig({
      endpoint: this.endpoint,
      endpointMetadata: this.endpointMetadata,
      endpointBatch: this.endpointBatch,
      projectPath: this.projectPath,
      dismissEndpoint: this.dismissEndpoint,
      showSuggestPopover: this.showSuggestPopover,
    });

    if (this.shouldShow) {
      this.fetchData();
    }

    const id = window && window.location && window.location.hash;

    if (id) {
      this.setHighlightedRow(id.slice(1));
    }
  },
  created() {
    this.adjustView();
    eventHub.$once('fetchedNotesData', this.setDiscussions);
    eventHub.$once('fetchDiffData', this.fetchData);
    eventHub.$on('refetchDiffData', this.refetchDiffData);
    this.CENTERED_LIMITED_CONTAINER_CLASSES = CENTERED_LIMITED_CONTAINER_CLASSES;
  },
  beforeDestroy() {
    eventHub.$off('fetchDiffData', this.fetchData);
    eventHub.$off('refetchDiffData', this.refetchDiffData);
    this.removeEventListeners();
  },
  methods: {
    ...mapActions(['startTaskList']),
    ...mapActions('diffs', [
      'setBaseConfig',
      'fetchDiffFiles',
      'fetchDiffFilesMeta',
      'fetchDiffFilesBatch',
      'startRenderDiffsQueue',
      'assignDiscussionsToDiff',
      'setHighlightedRow',
      'cacheTreeListWidth',
      'scrollToFile',
      'toggleShowTreeList',
    ]),
    refetchDiffData() {
      this.assignedDiscussions = false;
      this.fetchData(false);
    },
    isLatestVersion() {
      return window.location.search.indexOf('diff_id') === -1;
    },
    startDiffRendering() {
      requestIdleCallback(
        () => {
          this.startRenderDiffsQueue();
        },
        { timeout: 1000 },
      );
    },
    fetchData(toggleTree = true) {
      if (this.isLatestVersion() && this.glFeatures.diffsBatchLoad) {
        this.fetchDiffFilesMeta()
          .then(() => {
            if (toggleTree) this.hideTreeListIfJustOneFile();

            this.startDiffRendering();
          })
          .catch(() => {
            createFlash(__('Something went wrong on our end. Please try again!'));
          });

        this.fetchDiffFilesBatch()
          .then(() => this.startDiffRendering())
          .catch(() => {
            createFlash(__('Something went wrong on our end. Please try again!'));
          });
      } else {
        this.fetchDiffFiles()
          .then(() => {
            if (toggleTree) {
              this.hideTreeListIfJustOneFile();
            }

            requestIdleCallback(
              () => {
                this.startRenderDiffsQueue();
              },
              { timeout: 1000 },
            );
          })
          .catch(() => {
            createFlash(__('Something went wrong on our end. Please try again!'));
          });
      }

      if (!this.isNotesFetched) {
        eventHub.$emit('fetchNotesData');
      }
    },
    setDiscussions() {
      if (this.shouldSetDiscussions) {
        this.assignedDiscussions = true;

        requestIdleCallback(
          () =>
            this.assignDiscussionsToDiff()
              .then(this.$nextTick)
              .then(this.startTaskList),
          { timeout: 1000 },
        );
      }
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
    },
    removeEventListeners() {
      Mousetrap.unbind(['[', 'k', ']', 'j']);
    },
    jumpToFile(step) {
      const targetIndex = this.currentDiffIndex + step;
      if (targetIndex >= 0 && targetIndex < this.diffFiles.length) {
        this.scrollToFile(this.diffFiles[targetIndex].file_path);
      }
    },
    hideTreeListIfJustOneFile() {
      const storedTreeShow = localStorage.getItem(MR_TREE_SHOW_KEY);

      if ((storedTreeShow === null && this.diffFiles.length <= 1) || storedTreeShow === 'false') {
        this.toggleShowTreeList(false);
      }
    },
  },
  minTreeWidth: MIN_TREE_WIDTH,
  maxTreeWidth: MAX_TREE_WIDTH,
};
</script>

<template>
  <div v-show="shouldShow">
    <div v-if="isLoading" class="loading"><gl-loading-icon /></div>
    <div v-else id="diffs" :class="{ active: shouldShow }" class="diffs tab-pane">
      <compare-versions
        :merge-request-diffs="mergeRequestDiffs"
        :merge-request-diff="mergeRequestDiff"
        :target-branch="targetBranch"
        :is-limited-container="isLimitedContainer"
      />

      <hidden-files-warning
        v-if="renderOverflowWarning"
        :visible="numVisibleFiles"
        :total="numTotalFiles"
        :plain-diff-path="plainDiffPath"
        :email-patch-path="emailPatchPath"
      />

      <div
        :data-can-create-note="getNoteableData.current_user.can_create_note"
        class="files d-flex prepend-top-default"
      >
        <div
          v-show="showTreeList"
          :style="{ width: `${treeWidth}px` }"
          class="diff-tree-list js-diff-tree-list mr-3"
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
          class="diff-files-holder"
          :class="{
            [CENTERED_LIMITED_CONTAINER_CLASSES]: isLimitedContainer,
          }"
        >
          <commit-widget v-if="commit" :commit="commit" />
          <div v-if="isBatchLoading" class="loading"><gl-loading-icon /></div>
          <template v-else-if="renderDiffFiles">
            <diff-file
              v-for="file in diffFiles"
              :key="file.newPath"
              :file="file"
              :help-page-path="helpPagePath"
              :can-current-user-fork="canCurrentUserFork"
            />
          </template>
          <no-changes v-else :changes-empty-state-illustration="changesEmptyStateIllustration" />
        </div>
      </div>
    </div>
  </div>
</template>
