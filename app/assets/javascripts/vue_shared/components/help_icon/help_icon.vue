<script>
import { GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
  props: {
    size: {
      type: String,
      default: 'default',
      required: false,
    },
  },
  computed: {
    sizeInPx() {
      return this.$options.sizeMapping[this.size]
        ? this.$options.sizeMapping[this.size]
        : this.$options.sizeMapping.default;
    },
  },
  sizeMapping: {
    small: 12,
    default: 16,
  },
};
</script>
<template>
  <gl-icon
    v-bind="$attrs"
    name="question-o"
    :size="sizeInPx"
    variant="info"
    class="gl-cursor-help"
  />
</template>
