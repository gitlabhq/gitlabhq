<script>
/**
 * Renders a terminal button to open a web terminal.
 * Used in environments table.
 */
import { GlDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlDropdownItem,
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
  title: __('Terminal'),
};
</script>
<template>
  <gl-dropdown-item :href="terminalPath" :disabled="disabled">
    {{ $options.title }}
  </gl-dropdown-item>
</template>
