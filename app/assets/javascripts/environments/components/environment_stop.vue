<script>
/**
 * Renders the stop "button" that allows stop an environment.
 * Used in environments table.
 */

import $ from 'jquery';
import { GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import { s__ } from '~/locale';
import eventHub from '../event_hub';
import LoadingButton from '../../vue_shared/components/loading_button.vue';

export default {
  components: {
    Icon,
    LoadingButton,
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
  <loading-button
    v-gl-tooltip
    :loading="isLoading"
    :title="title"
    :aria-label="title"
    container-class="btn btn-danger d-none d-sm-none d-md-block"
    data-toggle="modal"
    data-target="#stop-environment-modal"
    @click="onClick"
  >
    <icon name="stop" />
  </loading-button>
</template>
