<script>
import TreePage from './tree.vue';
import { updateElementsVisibility } from '../utils/dom';

export default {
  components: {
    TreePage,
  },
  mounted() {
    this.updateProjectElements(true);
  },
  beforeDestroy() {
    this.updateProjectElements(false);
  },
  methods: {
    updateProjectElements(isShow) {
      updateElementsVisibility('.js-show-on-project-root', isShow);
    },
  },
};
</script>

<template>
  <tree-page path="/" />
</template>
