<script>
import { GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
  props: {
    icon: {
      type: String,
      required: false,
      default: null,
    },
    padding: {
      type: String,
      default: 'gl-py-2',
      required: false,
    },
    dashed: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    borderClass() {
      return this.dashed ? 'gl-border-b-solid gl-border-gray-100 gl-border-b-1' : '';
    },
  },
};
</script>

<template>
  <div
    class="gl-display-flex gl-align-items-center gl-font-monospace gl-font-sm gl-word-break-all"
    :class="[padding, borderClass]"
  >
    <gl-icon v-if="icon" :name="icon" class="gl-mr-4" />
    <span>
      <slot></slot>
    </span>
  </div>
</template>
