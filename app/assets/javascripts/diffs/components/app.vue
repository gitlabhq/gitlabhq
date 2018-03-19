<script>
import { mapState, mapActions } from 'vuex';
import loadingIcon from '../../vue_shared/components/loading_icon.vue';
import compareVersions from './compare_versions.vue';
import changedFiles from './changed_files.vue';
import diffFile from './diff_file.vue';

export default {
  name: 'DiffsApp',
  components: {
    loadingIcon,
    compareVersions,
    changedFiles,
    diffFile,
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
    }),
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
  </div>
</template>
