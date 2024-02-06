<script>
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  directives: {
    SafeHtml,
  },
  props: {
    color: {
      type: String,
      required: true,
    },
  },
  computed: {
    style() {
      return {
        backgroundColor: this.color,
      };
    },
  },
};
</script>
<template>
  <span>
    <span
      :style="style"
      data-testid="color-chip"
      class="gl-display-inline-block gl-w-5 gl-h-5 gl-rounded-base gl-vertical-align-middle gl-mr-1"
    ></span>
    <span
      v-safe-html="color"
      class="gl-display-inline-block gl-vertical-align-middle"
      data-testid="color-value"
    ></span>
  </span>
</template>
