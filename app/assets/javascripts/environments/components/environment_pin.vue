<script>
/**
 * Renders a prevent auto-stop button.
 * Used in environments table.
 */
import { GlDeprecatedButton, GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import { __ } from '~/locale';
import eventHub from '../event_hub';

export default {
  components: {
    Icon,
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
    <icon name="thumbtack" />
  </gl-deprecated-button>
</template>
