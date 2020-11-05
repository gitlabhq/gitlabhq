<script>
/**
 * Renders the stop "button" that allows stop an environment.
 * Used in environments table.
 */

import { GlTooltipDirective, GlButton, GlModalDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import eventHub from '../event_hub';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModalDirective,
  },
  props: {
    environment: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    title() {
      return s__('Environments|Stop environment');
    },
  },
  mounted() {
    eventHub.$on('stopEnvironment', this.onStopEnvironment);
  },
  beforeDestroy() {
    eventHub.$off('stopEnvironment', this.onStopEnvironment);
  },
  methods: {
    onClick() {
      this.$root.$emit('bv::hide::tooltip', this.$options.stopEnvironmentTooltipId);
      eventHub.$emit('requestStopEnvironment', this.environment);
    },
    onStopEnvironment(environment) {
      if (this.environment.id === environment.id) {
        this.isLoading = true;
      }
    },
  },
  stopEnvironmentTooltipId: 'stop-environment-button-tooltip',
};
</script>
<template>
  <gl-button
    v-gl-tooltip="{ id: $options.stopEnvironmentTooltipId }"
    v-gl-modal-directive="'stop-environment-modal'"
    :loading="isLoading"
    :title="title"
    :aria-label="title"
    icon="stop"
    category="primary"
    variant="danger"
    @click="onClick"
  />
</template>
