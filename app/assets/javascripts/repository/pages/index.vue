<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { updateElementsVisibility } from '../utils/dom';
import TreePage from './tree.vue';

export default {
  components: {
    TreePage,
  },
  props: {
    refType: {
      type: String,
      required: false,
      default: null,
    },
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
  <tree-page path="/" :ref-type="refType" />
</template>
