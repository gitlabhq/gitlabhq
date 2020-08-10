<script>
/**
 * Renders the stop "button" that allows stop an environment.
 * Used in environments table.
 */

import $ from 'jquery';
import { GlTooltipDirective, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import eventHub from '../event_hub';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
      $(this.$el).tooltip('dispose');
      eventHub.$emit('requestStopEnvironment', this.environment);
    },
    onStopEnvironment(environment) {
      if (this.environment.id === environment.id) {
        this.isLoading = true;
      }
    },
  },
};
</script>
<template>
  <gl-button
    v-gl-tooltip
    :loading="isLoading"
    :title="title"
    :aria-label="title"
    icon="stop"
    category="primary"
    variant="danger"
    data-toggle="modal"
    data-target="#stop-environment-modal"
    @click="onClick"
  />
</template>
