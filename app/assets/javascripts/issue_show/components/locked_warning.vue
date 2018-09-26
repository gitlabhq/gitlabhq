<script>
  import { Alert } from '@gitlab-org/gitlab-ui';

  export default {
    components: {
      'gl-alert': Alert,
    },
    computed: {
      currentPath() {
        return window.location.pathname;
      },
    },
  };
</script>

<template>
  <gl-alert
    variant="danger"
  >
    Someone edited the issue at the same time you did. Please check out
    <a
      :href="currentPath"
      target="_blank"
      rel="nofollow">the issue</a>
    and make sure your changes will not unintentionally remove theirs.
  </gl-alert>
</template>
