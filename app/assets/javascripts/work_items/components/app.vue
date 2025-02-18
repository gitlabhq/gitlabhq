<script>
export default {
  props: {
    newCommentTemplatePaths: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
};
</script>

<template>
  <router-view :new-comment-template-paths="newCommentTemplatePaths" />
</template>
