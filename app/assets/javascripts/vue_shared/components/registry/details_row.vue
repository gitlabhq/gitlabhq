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
    class="gl-display-flex gl-align-items-top gl-font-monospace gl-font-sm gl-break-all"
    :class="[padding, borderClass]"
  >
    <div v-if="icon" class="gl-w-5 gl-mr-4">
      <gl-icon :name="icon" />
    </div>
    <div>
      <slot></slot>
    </div>
  </div>
</template>
