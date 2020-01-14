<script>
import TreeContent from '../components/tree_content.vue';
import { updateElementsVisibility } from '../utils/dom';
import preloadMixin from '../mixins/preload';

export default {
  components: {
    TreeContent,
  },
  mixins: [preloadMixin],
  props: {
    path: {
      type: String,
      required: false,
      default: '/',
    },
  },
  computed: {
    isRoot() {
      return this.path === '/';
    },
  },
  watch: {
    isRoot: {
      immediate: true,
      handler: 'updateElements',
    },
  },
  methods: {
    updateElements(isRoot) {
      updateElementsVisibility('.js-show-on-root', isRoot);
      updateElementsVisibility('.js-hide-on-root', !isRoot);
    },
  },
};
</script>

<template>
  <tree-content :path="path" :loading-path="loadingPath" />
</template>
