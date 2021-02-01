<script>
import { updateElementsVisibility } from '../utils/dom';
import TreePage from './tree.vue';

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
