<script>
/**
 * Renders the delete button that allows deleting a stopped environment.
 * Used in the environments table.
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
      return s__('Environments|Delete environment');
    },
  },
  mounted() {
    eventHub.$on('deleteEnvironment', this.onDeleteEnvironment);
  },
  beforeDestroy() {
    eventHub.$off('deleteEnvironment', this.onDeleteEnvironment);
  },
  methods: {
    onClick() {
      this.$root.$emit('bv::hide::tooltip', this.$options.deleteEnvironmentTooltipId);
      eventHub.$emit('requestDeleteEnvironment', this.environment);
    },
    onDeleteEnvironment(environment) {
      if (this.environment.id === environment.id) {
        this.isLoading = true;
      }
    },
  },
  deleteEnvironmentTooltipId: 'delete-environment-button-tooltip',
};
</script>
<template>
  <gl-button
    v-gl-tooltip="{ id: $options.deleteEnvironmentTooltipId }"
    v-gl-modal-directive="'delete-environment-modal'"
    :loading="isLoading"
    :title="title"
    :aria-label="title"
    class="gl-display-none gl-display-md-block"
    variant="danger"
    category="primary"
    icon="remove"
    @click="onClick"
  />
</template>
