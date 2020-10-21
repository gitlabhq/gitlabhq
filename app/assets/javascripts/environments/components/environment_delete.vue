<script>
/**
 * Renders the delete button that allows deleting a stopped environment.
 * Used in the environments table and the environment detail view.
 */

import { GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import eventHub from '../event_hub';
import LoadingButton from '../../vue_shared/components/loading_button.vue';

export default {
  components: {
    GlIcon,
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
  <loading-button
    v-gl-tooltip="{ id: $options.deleteEnvironmentTooltipId }"
    :loading="isLoading"
    :title="title"
    :aria-label="title"
    container-class="btn btn-danger d-none d-md-block"
    data-toggle="modal"
    data-target="#delete-environment-modal"
    @click="onClick"
  >
    <gl-icon name="remove" />
  </loading-button>
</template>
