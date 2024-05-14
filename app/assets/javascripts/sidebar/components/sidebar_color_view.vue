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
    colorName: {
      type: String,
      required: false,
      default: '',
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
      class="gl-display-inline-block gl-w-5 gl-h-5 gl-rounded-base gl-align-middle gl-mr-1 gl-border-solid gl-border-gray-a-24"
    ></span>
    <span v-if="colorName" class="gl-display-inline-block gl-align-middle">
      {{ colorName }}
    </span>
    <span
      v-else
      v-safe-html="color"
      class="gl-display-inline-block gl-align-middle"
      data-testid="color-value"
    ></span>
  </span>
</template>
