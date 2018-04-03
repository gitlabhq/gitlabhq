<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import loadingIcon from '../../vue_shared/components/loading_icon.vue';
import compareVersions from './compare_versions.vue';
import changedFiles from './changed_files.vue';
import diffFile from './diff_file.vue';
import NoChanges from './no_changes.vue';

export default {
  name: 'DiffsApp',
  components: {
    loadingIcon,
    compareVersions,
    changedFiles,
    diffFile,
    NoChanges,
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
    }),
    ...mapGetters(['isParallelView']),
  },
  mounted() {
    this.setEndpoint(this.endpoint);
    this.fetchDiffFiles(); // TODO: @fatihacet Error handling
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
        return window.mrTabs.expandViewContainer();
      }

      window.mrTabs.resetViewContainer();
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
  created() {
    this.adjustView();
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
      id="diffs"
      class="diffs tab-pane"
    >
      <div v-if="diffFiles.length">
        <compare-versions />
        <changed-files
          :diff-files="diffFiles"
          :active-file="activeFile"
        />
        <div class="files">
          <diff-file
            @setActive="setActive(file.filePath)"
            @unsetActive="unsetActive(file.filePath)"
            v-for="file in diffFiles"
            :key="file.newPath"
            :file="file"
          />
        </div>
      </div>
      <no-changes v-else />
    </div>
  </div>
</template>
