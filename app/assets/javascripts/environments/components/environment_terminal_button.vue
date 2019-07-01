<script>
/**
 * Renders a terminal button to open a web terminal.
 * Used in environments table.
 */
import { GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import { __ } from '~/locale';

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
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    title() {
      return __('Terminal');
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
    :class="{ disabled: disabled }"
    class="btn terminal-button d-none d-sm-none d-md-block text-secondary"
  >
    <icon name="terminal" />
  </a>
</template>
