<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
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
  data() {
    return {
      activeFile: '',
    };
  },
  computed: {
    ...mapState({
      isLoading: state => state.diffs.isLoading,
      diffFiles: state => state.diffs.diffFiles,
      diffViewType: state => state.diffs.diffViewType,
      comparableDiffs: state => state.diffs.comparableDiffs,
      mergeRequestDiffs: state => state.diffs.mergeRequestDiffs,
      mergeRequestDiff: state => state.diffs.mergeRequestDiff,
      startVersion: state => state.diffs.startVersion,
      targetBranchName: state => state.diffs.targetBranchName,
      renderOverflowWarning: state => state.diffs.renderOverflowWarning,
      numTotalFiles: state => state.diffs.realSize,
      numVisibleFiles: state => state.diffs.size,
      plainDiffPath: state => state.diffs.plainDiffPath,
      emailPatchPath: state => state.diffs.emailPatchPath,
    }),
    ...mapGetters(['isParallelView']),
    targetBranch() {
      return {
        branchName: this.targetBranchName,
        versionIndex: -1,
        path: '',
      };
    },
  },
  watch: {
    diffViewType() {
      this.adjustView();
    },
    shouldShow() {
      this.adjustView();
    },
  },
  mounted() {
    this.setEndpoint(this.endpoint);
    this.fetchDiffFiles(); // TODO: @fatihacet Error handling
  },
  created() {
    this.adjustView();
  },
  methods: {
    ...mapActions(['setEndpoint', 'fetchDiffFiles']),
    setActive(filePath) {
      this.activeFile = filePath;
    },
    unsetActive(filePath) {
      if (this.activeFile === filePath) {
        this.activeFile = '';
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
  <div v-if="shouldShow">
    <div
      v-if="isLoading"
      class="loading"
    >
      <loading-icon />
    </div>
    <div
      v-else
      :class="{ active: shouldShow }"
      id="diffs"
      class="diffs tab-pane"
    >
      <compare-versions
        v-if="mergeRequestDiffs.length > 1"
        :merge-request-diffs="mergeRequestDiffs"
        :comparable-diffs="comparableDiffs"
        :merge-request-diff="mergeRequestDiff"
        :start-version="startVersion"
        :target-branch="targetBranch"
      />
      <changed-files
        v-if="diffFiles.length > 0"
        :diff-files="diffFiles"
        :active-file="activeFile"
      />

      <hidden-files-warning
        v-if="renderOverflowWarning"
        :visible="numVisibleFiles"
        :total="numTotalFiles"
        :plain-diff-path="plainDiffPath"
        :email-patch-path="emailPatchPath"
      />

      <div
        v-if="diffFiles.length"
        class="files"
      >
        <diff-file
          v-for="file in diffFiles"
          :key="file.newPath"
          :file="file"
          :current-user="currentUser"
          @setActive="setActive(file.filePath)"
          @unsetActive="unsetActive(file.filePath)"
        />
      </div>
      <no-changes v-else />
    </div>
  </div>
</template>
