<script>
  /**
  * Renders a terminal button to open a web terminal.
  * Used in environments table.
  */
  import Icon from '~/vue_shared/components/icon.vue';
  import tooltip from '../../vue_shared/directives/tooltip';

  export default {
    components: {
      Icon,
    },
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
  >
    <icon
      name="terminal"
      :size="12"
    />
  </a>
</template>
