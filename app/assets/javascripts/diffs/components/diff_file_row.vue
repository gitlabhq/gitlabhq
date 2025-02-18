<script>
/**
 * This component is an iterative step towards refactoring and simplifying `vue_shared/components/file_row.vue`
 * https://gitlab.com/gitlab-org/gitlab/-/merge_requests/23720
 */
import ChangedFileIcon from '~/vue_shared/components/changed_file_icon.vue';
import FileRow from '~/vue_shared/components/file_row.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import FileRowStats from './file_row_stats.vue';

export default {
  name: 'DiffFileRow',
  components: {
    FileRow,
    FileRowStats,
    ChangedFileIcon,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    file: {
      type: Object,
      required: true,
    },
    hideFileStats: {
      type: Boolean,
      required: true,
    },
    currentDiffFileId: {
      type: String,
      required: false,
      default: null,
    },
    viewedFiles: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    showFileRowStats() {
      return !this.hideFileStats && this.file.type === 'blob';
    },
    fileClasses() {
      return this.file.type === 'blob' && !this.viewedFiles[this.file.id]
        ? 'gl-font-bold'
        : 'gl-text-subtle';
    },
    isActive() {
      return this.currentDiffFileId === this.file.fileHash;
    },
  },
};
</script>

<template>
  <file-row
    :file="file"
    v-bind="$attrs"
    :class="{ 'is-active': isActive }"
    class="diff-file-row"
    truncate-middle
    :file-classes="fileClasses"
    v-on="$listeners"
  >
    <file-row-stats v-if="showFileRowStats" :file="file" class="gl-mr-2" />
    <changed-file-icon :file="file" :size="16" :show-tooltip="true" />
  </file-row>
</template>
