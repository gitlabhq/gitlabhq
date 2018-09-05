<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import { __ } from '~/locale';
import createFlash from '~/flash';
import eventHub from '../../notes/event_hub';
import LoadingIcon from '../../vue_shared/components/loading_icon.vue';
import CompareVersions from './compare_versions.vue';
import ChangedFiles from './changed_files.vue';
import DiffFile from './diff_file.vue';
import NoChanges from './no_changes.vue';
import HiddenFilesWarning from './hidden_files_warning.vue';

export default {
  name: 'DiffsApp',
  components: {
    Icon,
    LoadingIcon,
    CompareVersions,
    ChangedFiles,
    DiffFile,
    NoChanges,
    HiddenFilesWarning,
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
  },
  computed: {
    ...mapState({
      isLoading: state => state.diffs.isLoading,
      diffFiles: state => state.diffs.diffFiles,
      diffViewType: state => state.diffs.diffViewType,
      mergeRequestDiffs: state => state.diffs.mergeRequestDiffs,
      mergeRequestDiff: state => state.diffs.mergeRequestDiff,
      latestVersionPath: state => state.diffs.latestVersionPath,
      startVersion: state => state.diffs.startVersion,
      commit: state => state.diffs.commit,
      targetBranchName: state => state.diffs.targetBranchName,
      renderOverflowWarning: state => state.diffs.renderOverflowWarning,
      numTotalFiles: state => state.diffs.realSize,
      numVisibleFiles: state => state.diffs.size,
      plainDiffPath: state => state.diffs.plainDiffPath,
      emailPatchPath: state => state.diffs.emailPatchPath,
    }),
    ...mapGetters('diffs', ['isParallelView']),
    ...mapGetters(['isNotesFetched', 'discussionsStructuredByLineCode']),
    targetBranch() {
      return {
        branchName: this.targetBranchName,
        versionIndex: -1,
        path: '',
      };
    },
    notAllCommentsDisplayed() {
      if (this.commit) {
        return __('Only comments from the following commit are shown below');
      } else if (this.startVersion) {
        return __(
          "Not all comments are displayed because you're comparing two versions of the diff.",
        );
      }
      return __(
        "Not all comments are displayed because you're viewing an old version of the diff.",
      );
    },
    showLatestVersion() {
      if (this.commit) {
        return __('Show latest version of the diff');
      }
      return __('Show latest version');
    },
    canCurrentUserFork() {
      return this.currentUser.canFork === true && this.currentUser.canCreateMergeRequest;
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
  },
  mounted() {
    this.setBaseConfig({ endpoint: this.endpoint, projectPath: this.projectPath });

    if (this.shouldShow) {
      this.fetchData();
    }
  },
  created() {
    this.adjustView();
    eventHub.$once('fetchedNotesData', this.setDiscussions);
  },
  methods: {
    ...mapActions('diffs', [
      'setBaseConfig',
      'fetchDiffFiles',
      'startRenderDiffsQueue',
      'assignDiscussionsToDiff',
    ]),

    fetchData() {
      this.fetchDiffFiles()
        .then(() => {
          requestIdleCallback(
            () => {
              this.startRenderDiffsQueue()
                .then(() => {
                  this.setDiscussions();
                })
                .catch(() => {
                  createFlash(__('Something went wrong on our end. Please try again!'));
                });
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
      if (this.isNotesFetched) {
        requestIdleCallback(
          () => {
            this.assignDiscussionsToDiff(this.discussionsStructuredByLineCode);
          },
          { timeout: 1000 },
        );
      }
    },
    adjustView() {
      if (this.shouldShow && this.isParallelView) {
        window.mrTabs.expandViewContainer();
      } else {
        window.mrTabs.resetViewContainer();
      }
    },
  },
};
</script>

<template>
  <div v-show="shouldShow">
    <div
      v-if="isLoading"
      class="loading"
    >
      <loading-icon />
    </div>
    <div
      v-else
      id="diffs"
      :class="{ active: shouldShow }"
      class="diffs tab-pane"
    >
      <compare-versions
        v-if="!commit && mergeRequestDiffs.length > 1"
        :merge-request-diffs="mergeRequestDiffs"
        :merge-request-diff="mergeRequestDiff"
        :start-version="startVersion"
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
        v-if="commit || startVersion || (mergeRequestDiff && !mergeRequestDiff.latest)"
        class="mr-version-controls"
      >
        <div class="content-block comments-disabled-notif clearfix">
          <i class="fa fa-info-circle"></i>
          {{ notAllCommentsDisplayed }}
          <div class="pull-right">
            <a
              :href="latestVersionPath"
              class="btn btn-sm"
            >
              {{ showLatestVersion }}
            </a>
          </div>
        </div>
      </div>

      <changed-files
        :diff-files="diffFiles"
      />

      <div
        v-if="diffFiles.length > 0"
        class="files"
      >
        <diff-file
          v-for="file in diffFiles"
          :key="file.newPath"
          :file="file"
          :can-current-user-fork="canCurrentUserFork"
        />
      </div>
      <no-changes v-else />
    </div>
  </div>
</template>
