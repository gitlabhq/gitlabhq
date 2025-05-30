<script>
export default {
  props: {
    newCommentTemplatePaths: {
      type: Array,
      required: false,
      default: () => [],
    },
    urlFullPath: {
      type: String,
      required: false,
      default: undefined,
    },
    withTabs: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    pageKey() {
      return this.$route.params.iid || this.$route.name;
    },
  },
};
</script>

<template>
  <router-view
    :key="pageKey"
    :new-comment-template-paths="newCommentTemplatePaths"
    :url-full-path="urlFullPath"
    :with-tabs="withTabs"
    data-testid="work-item-router-view"
  />
</template>
