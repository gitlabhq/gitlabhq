<!-- eslint-disable vue/multi-word-component-names -->
<script>
import TreeContent from 'jh_else_ce/repository/components/tree_content.vue';
import preloadMixin from '../mixins/preload';
import repositoryPathMixin from '../mixins/repository_path';
import { updateElementsVisibility } from '../utils/dom';

export default {
  components: {
    TreeContent,
  },
  mixins: [preloadMixin, repositoryPathMixin],
  provide() {
    return {
      refType: this.refType,
    };
  },
  props: {
    refType: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    isRoot() {
      return this.computedPath === '/';
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
  <tree-content :path="computedPath" :loading-path="loadingPath" />
</template>
