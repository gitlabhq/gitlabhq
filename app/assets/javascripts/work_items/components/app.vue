<script>
export default {
  props: {
    newCommentTemplatePaths: {
      type: Array,
      required: false,
      default: () => [],
    },
    withTabs: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
};
</script>

<template>
  <router-view :new-comment-template-paths="newCommentTemplatePaths" :with-tabs="withTabs" />
</template>
