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
      return this.isGroupOpen ? 'chevron-down' : 'chevron-right';
    },
  },
};
</script>

<template>
  <span class="folder-caret gl-display-inline-block gl-text-secondary gl-w-5 gl-mr-2">
    <gl-icon :size="12" :name="iconClass" />
  </span>
</template>
