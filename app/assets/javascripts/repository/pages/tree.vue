<!-- eslint-disable vue/multi-word-component-names -->
<script>
import TreeContent from 'jh_else_ce/repository/components/tree_content.vue';
import preloadMixin from '../mixins/preload';
import { updateElementsVisibility } from '../utils/dom';

export default {
  components: {
    TreeContent,
  },
  mixins: [preloadMixin],
  provide() {
    return {
      refType: this.refType,
    };
  },
  props: {
    path: {
      type: String,
      required: false,
      default: '/',
    },
    refType: {
      type: String,
      required: false,
      default: '',
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
