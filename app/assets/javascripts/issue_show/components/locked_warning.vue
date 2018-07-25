<script>
  export default {
    computed: {
      currentPath() {
        return window.location.pathname;
      },
    },
  };
</script>

<template>
  <div class="alert alert-danger">
    Someone edited the issue at the same time you did. Please check out
    <a
      :href="currentPath"
      target="_blank"
      rel="nofollow">the issue</a>
    and make sure your changes will not unintentionally remove theirs.
  </div>
</template>
