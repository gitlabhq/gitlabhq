<script>
/**
 * Renders a prevent auto-stop button.
 * Used in environments table.
 */
import { GlDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';
import eventHub from '../event_hub';

export default {
  components: {
    GlDropdownItem,
  },
  props: {
    autoStopUrl: {
      type: String,
      required: true,
    },
  },
  methods: {
    onPinClick() {
      eventHub.$emit('cancelAutoStop', this.autoStopUrl);
    },
  },
  title: __('Prevent auto-stopping'),
};
</script>
<template>
  <gl-dropdown-item @click="onPinClick">
    {{ $options.title }}
  </gl-dropdown-item>
</template>
