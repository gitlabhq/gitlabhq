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
    count: {
      type: Number,
      required: true,
    },
  },
};
</script>

<template>
  <a
    href="#"
    class="counter gl-relative gl-display-inline-block gl-flex-grow-1 gl-text-center gl-py-3 gl-bg-gray-10 gl-rounded-base gl-text-black-normal gl-border gl-border-gray-a-08 gl-font-sm gl-font-weight-bold"
  >
    <gl-icon :name="icon" />
    {{ count }}
  </a>
</template>
