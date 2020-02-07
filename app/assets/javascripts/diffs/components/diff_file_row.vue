<script>
/**
 * This component is an iterative step towards refactoring and simplifying `vue_shared/components/file_row.vue`
 * https://gitlab.com/gitlab-org/gitlab/-/merge_requests/23720
 */
import FileRow from '~/vue_shared/components/file_row.vue';

export default {
  components: {
    FileRow,
  },
};
</script>

<template>
  <file-row v-bind="$attrs" v-on="$listeners" />
</template>
