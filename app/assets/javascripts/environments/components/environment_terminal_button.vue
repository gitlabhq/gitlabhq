<script>
  /**
  * Renders a terminal button to open a web terminal.
  * Used in environments table.
  */
  import terminalIconSvg from 'icons/_icon_terminal.svg';
  import tooltip from '../../vue_shared/directives/tooltip';

  export default {
    directives: {
      tooltip,
    },

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
    v-tooltip
    class="btn terminal-button hidden-xs hidden-sm"
    data-container="body"
    :title="title"
    :aria-label="title"
    :href="terminalPath"
    v-html="terminalIconSvg"
  >
  </a>
</template>
