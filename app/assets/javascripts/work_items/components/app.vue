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
    :with-tabs="withTabs"
    data-testid="work-item-router-view"
  />
</template>
