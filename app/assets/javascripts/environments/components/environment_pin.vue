<script>
/**
 * Renders a prevent auto-stop button.
 * Used in environments table.
 */
import { GlButton, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import eventHub from '../event_hub';

export default {
  components: {
    GlIcon,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
  title: __('Prevent environment from auto-stopping'),
};
</script>
<template>
  <gl-button v-gl-tooltip :title="$options.title" :aria-label="$options.title" @click="onPinClick">
    <gl-icon name="thumbtack" />
  </gl-button>
</template>
