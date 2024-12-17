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
      return this.dashed ? 'gl-border-b-solid gl-border-default gl-border-b-1' : '';
    },
  },
};
</script>

<template>
  <div
    class="gl-align-items-top gl-flex gl-break-all gl-text-sm gl-font-monospace"
    :class="[padding, borderClass]"
  >
    <div v-if="icon" class="gl-mr-4 gl-w-5">
      <gl-icon :name="icon" />
    </div>
    <div>
      <slot></slot>
    </div>
  </div>
</template>
