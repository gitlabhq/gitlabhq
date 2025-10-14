<script>
import { createDebouncedVisibilityHandler } from '../utils/debounced_visibility_handler';

export default {
  name: 'BaseWidget',
  props: {
    applyDefaultStyling: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      debouncedVisibilityHandler: null,
    };
  },
  mounted() {
    this.debouncedVisibilityHandler = createDebouncedVisibilityHandler(() => this.$emit('visible'));
    document.addEventListener('visibilitychange', this.debouncedVisibilityHandler);
  },
  beforeDestroy() {
    if (this.debouncedVisibilityHandler) {
      document.removeEventListener('visibilitychange', this.debouncedVisibilityHandler);
    }
  },
};
</script>

<template>
  <div :class="{ 'gl-border gl-rounded-pill gl-p-5': applyDefaultStyling }">
    <slot></slot>
  </div>
</template>
