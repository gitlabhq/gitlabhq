<script>
/**
 * Renders Rollback or Re deploy button in environments table depending
 * of the provided property `isLastDeployment`.
 *
 * Makes a post request when the button is clicked.
 */
import { GlTooltipDirective, GlLoadingIcon, GlModalDirective, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import eventHub from '../event_hub';

export default {
  components: {
    Icon,
    GlLoadingIcon,
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
      eventHub.$on('rollbackEnvironment', environment => {
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
    :disabled="isLoading"
    :title="title"
    class="d-none d-md-block text-secondary"
    @click="onClick"
  >
    <icon v-if="isLastDeployment" name="repeat" /> <icon v-else name="redo" />
    <gl-loading-icon v-if="isLoading" />
  </gl-button>
</template>
