<script>
/**
 * Renders a terminal button to open a web terminal.
 * Used in environments table.
 */
import terminalIconSvg from 'icons/_icon_terminal.svg';

export default {
  props: {
    terminalPath: {
      type: String,
      required: false,
      default: '',
    },
  },

  data() {
    return {
      terminalIconSvg,
    };
  },

  computed: {
    title() {
      return 'Terminal';
    },
  },
};
</script>
<template>
  <a
    class="btn terminal-button has-tooltip"
    data-container="body"
    :title="title"
    :aria-label="title"
    :href="terminalPath"
    v-html="terminalIconSvg">
  </a>
</template>
