<script>
/**
 * Renders a terminal button to open a web terminal.
 * Used in environments table.
 */
import { GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
    v-gl-tooltip
    :title="title"
    :aria-label="title"
    :href="terminalPath"
    class="btn terminal-button d-none d-sm-none d-md-block"
  >
    <icon name="terminal" />
  </a>
</template>
