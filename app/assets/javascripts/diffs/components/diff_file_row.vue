<script>
/**
 * This component is an iterative step towards refactoring and simplifying `vue_shared/components/file_row.vue`
 * https://gitlab.com/gitlab-org/gitlab/-/merge_requests/23720
 */
import FileRow from '~/vue_shared/components/file_row.vue';
import FileRowStats from './file_row_stats.vue';

export default {
  name: 'DiffFileRow',
  components: {
    FileRow,
    FileRowStats,
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
  },
  computed: {
    showFileRowStats() {
      return !this.hideFileStats && this.file.type === 'blob';
    },
  },
};
</script>

<template>
  <file-row :file="file" :hide-file-stats="hideFileStats" v-bind="$attrs" v-on="$listeners">
    <file-row-stats v-if="showFileRowStats" :file="file" />
  </file-row>
</template>
