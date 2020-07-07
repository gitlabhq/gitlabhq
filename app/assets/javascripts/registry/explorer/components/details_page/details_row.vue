<script>
import { GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
  props: {
    icon: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div
    class="gl-display-flex gl-align-items-center gl-font-monospace gl-font-sm gl-py-2 gl-word-break-all"
  >
    <gl-icon :name="icon" class="gl-mr-4" />
    <span>
      <slot></slot>
    </span>
  </div>
</template>
