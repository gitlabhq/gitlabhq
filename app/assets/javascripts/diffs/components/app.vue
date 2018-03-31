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
    expandDiffs() {
      window.mrTabs.expandViewContainer();
    },
    shrinkDiffs() {
      window.mrTabs.resetViewContainer();
    },
  },
  watch: {
    diffViewType() {
      return this.isParallelView ? this.expandDiffs() : this.shrinkDiffs();
    },
  },
  created() {
    if (this.isParallelView) {
      this.expandDiffs();
    }
  },
};
</script>

<template>
  <div v-if="shouldShow">
    <loading-icon
      v-if="isLoading"
      size="3"
    />
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
