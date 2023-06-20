<script>
/**
 * Renders a terminal button to open a web terminal.
 * Used in environments table.
 */
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlDisclosureDropdownItem,
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
  data() {
    return {
      item: { text: __('Terminal'), href: this.terminalPath },
    };
  },
};
</script>
<template>
  <gl-disclosure-dropdown-item :item="item" :disabled="disabled" />
</template>
