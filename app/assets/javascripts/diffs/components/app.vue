<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import { __ } from '~/locale';
import createFlash from '~/flash';
import { GlLoadingIcon } from '@gitlab/ui';
import eventHub from '../../notes/event_hub';
import CompareVersions from './compare_versions.vue';
import DiffFile from './diff_file.vue';
import NoChanges from './no_changes.vue';
import HiddenFilesWarning from './hidden_files_warning.vue';
import CommitWidget from './commit_widget.vue';
import TreeList from './tree_list.vue';

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
  },
  props: {
    endpoint: {
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
  },
  data() {
    return {
      assignedDiscussions: false,
    };
  },
  computed: {
    ...mapState({
      isLoading: state => state.diffs.isLoading,
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
    ...mapGetters('diffs', ['isParallelView']),
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
  },
  mounted() {
    this.setBaseConfig({ endpoint: this.endpoint, projectPath: this.projectPath });

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
  },
  beforeDestroy() {
    eventHub.$off('fetchDiffData', this.fetchData);
  },
  methods: {
    ...mapActions(['startTaskList']),
    ...mapActions('diffs', [
      'setBaseConfig',
      'fetchDiffFiles',
      'startRenderDiffsQueue',
      'assignDiscussionsToDiff',
      'setHighlightedRow',
    ]),
    fetchData() {
      this.fetchDiffFiles()
        .then(() => {
          requestIdleCallback(
            () => {
              this.setDiscussions();
              this.startRenderDiffsQueue();
            },
            { timeout: 1000 },
          );
        })
        .catch(() => {
          createFlash(__('Something went wrong on our end. Please try again!'));
        });

      if (!this.isNotesFetched) {
        eventHub.$emit('fetchNotesData');
      }
    },
    setDiscussions() {
      if (this.isNotesFetched && !this.assignedDiscussions && !this.isLoading) {
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
          window.mrTabs.resetViewContainer();
          window.mrTabs.expandViewContainer(this.showTreeList);
        });
      }
    },
  },
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
        <div v-show="showTreeList" class="diff-tree-list"><tree-list /></div>
        <div class="diff-files-holder">
          <commit-widget v-if="commit" :commit="commit" />
          <template v-if="renderDiffFiles">
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
