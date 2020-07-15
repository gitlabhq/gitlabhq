<script>
/**
 * This component is an iterative step towards refactoring and simplifying `vue_shared/components/file_row.vue`
 * https://gitlab.com/gitlab-org/gitlab/-/merge_requests/23720
 */
import FileRow from '~/vue_shared/components/file_row.vue';
import FileRowStats from './file_row_stats.vue';
import ChangedFileIcon from '~/vue_shared/components/changed_file_icon.vue';

export default {
  name: 'DiffFileRow',
  components: {
    FileRow,
    FileRowStats,
    ChangedFileIcon,
  },
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
  },
  computed: {
    showFileRowStats() {
      return !this.hideFileStats && this.file.type === 'blob';
    },
  },
};
</script>

<template>
  <file-row
    :file="file"
    v-bind="$attrs"
    :class="{ 'is-active': currentDiffFileId === file.fileHash }"
    class="diff-file-row"
    v-on="$listeners"
  >
    <file-row-stats v-if="showFileRowStats" :file="file" class="mr-1" />
    <changed-file-icon :file="file" :size="16" :show-tooltip="true" />
  </file-row>
</template>
