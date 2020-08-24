<script>
/**
 * Renders a prevent auto-stop button.
 * Used in environments table.
 */
import { GlDeprecatedButton, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import eventHub from '../event_hub';

export default {
  components: {
    GlIcon,
    GlDeprecatedButton,
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
  <gl-deprecated-button
    v-gl-tooltip
    :title="$options.title"
    :aria-label="$options.title"
    @click="onPinClick"
  >
    <gl-icon name="thumbtack" />
  </gl-deprecated-button>
</template>
