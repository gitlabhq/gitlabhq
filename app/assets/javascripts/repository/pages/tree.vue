<script>
import TreeContent from '../components/tree_content.vue';

export default {
  components: {
    TreeContent,
  },
  props: {
    path: {
      type: String,
      required: false,
      default: '/',
    },
  },
};
</script>

<template>
  <tree-content :path="path" />
</template>
