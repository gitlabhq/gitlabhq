<script>
/**
 * Renders Rollback or Re deploy button in environments table depending
 * of the provided property `isLastDeployment`.
 *
 * Makes a post request when the button is clicked.
 */
import { GlTooltipDirective, GlModalDirective, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import eventHub from '../event_hub';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  props: {
    isLastDeployment: {
      type: Boolean,
      default: true,
      required: false,
    },

    environment: {
      type: Object,
      required: true,
    },

    retryUrl: {
      type: String,
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
      return this.isLastDeployment
        ? s__('Environments|Re-deploy to environment')
        : s__('Environments|Rollback environment');
    },
  },

  methods: {
    onClick() {
      eventHub.$emit('requestRollbackEnvironment', {
        ...this.environment,
        retryUrl: this.retryUrl,
        isLastDeployment: this.isLastDeployment,
      });
      eventHub.$on('rollbackEnvironment', (environment) => {
        if (environment.id === this.environment.id) {
          this.isLoading = true;
        }
      });
    },
  },
};
</script>
<template>
  <gl-button
    v-gl-tooltip
    v-gl-modal.confirm-rollback-modal
    class="gl-display-none gl-md-display-block text-secondary"
    :loading="isLoading"
    :title="title"
    :aria-label="title"
    :icon="isLastDeployment ? 'repeat' : 'redo'"
    @click="onClick"
  />
</template>
