<script>
import { GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
  props: {
    isGroupOpen: {
      type: Boolean,
      required: true,
      default: false,
    },
  },
  computed: {
    iconClass() {
      return this.isGroupOpen ? 'angle-down' : 'angle-right';
    },
  },
};
</script>

<template>
  <span class="folder-caret gl-mr-2">
    <gl-icon :size="10" :name="iconClass" use-deprecated-sizes />
  </span>
</template>
