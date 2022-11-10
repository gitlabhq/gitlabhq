<script>
/**
 * Renders Rollback or Re deploy button in environments table depending
 * of the provided property `isLastDeployment`.
 *
 * Makes a post request when the button is clicked.
 */
import { GlModalDirective, GlDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';
import eventHub from '../event_hub';
import setEnvironmentToRollback from '../graphql/mutations/set_environment_to_rollback.mutation.graphql';

export default {
  components: {
    GlDropdownItem,
  },
  directives: {
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

    graphql: {
      type: Boolean,
      required: false,
      default: false,
    },
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
      const rollbackEnvironmentData = {
        ...this.environment,
        retryUrl: this.retryUrl,
        isLastDeployment: this.isLastDeployment,
      };
      if (this.graphql) {
        this.$apollo.mutate({
          mutation: setEnvironmentToRollback,
          variables: {
            environment: rollbackEnvironmentData,
          },
        });
      } else {
        eventHub.$emit('requestRollbackEnvironment', rollbackEnvironmentData);
      }
    },
  },
};
</script>
<template>
  <gl-dropdown-item v-gl-modal.confirm-rollback-modal @click="onClick">
    {{ title }}
  </gl-dropdown-item>
</template>
