<script>
/**
 * Renders the stop "button" that allows stop an environment.
 * Used in environments table.
 */

import { GlTooltipDirective, GlButton, GlModalDirective } from '@gitlab/ui';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { s__ } from '~/locale';
import eventHub from '../event_hub';
import setEnvironmentToStopMutation from '../graphql/mutations/set_environment_to_stop.mutation.graphql';
import isEnvironmentStoppingQuery from '../graphql/queries/is_environment_stopping.query.graphql';

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
    graphql: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  apollo: {
    isEnvironmentStopping: {
      query: isEnvironmentStoppingQuery,
      variables() {
        return { environment: this.environment };
      },
    },
  },
  i18n: {
    title: s__('Environments|Stop environment'),
  },
  data() {
    return {
      isLoading: false,
      isEnvironmentStopping: false,
    };
  },
  mounted() {
    eventHub.$on('stopEnvironment', this.onStopEnvironment);
  },
  beforeDestroy() {
    eventHub.$off('stopEnvironment', this.onStopEnvironment);
  },
  methods: {
    onClick() {
      this.$root.$emit(BV_HIDE_TOOLTIP, this.$options.stopEnvironmentTooltipId);
      if (this.graphql) {
        this.$apollo.mutate({
          mutation: setEnvironmentToStopMutation,
          variables: { environment: this.environment },
        });
      } else {
        eventHub.$emit('requestStopEnvironment', this.environment);
      }
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
    :loading="isLoading || isEnvironmentStopping"
    :title="$options.i18n.title"
    :aria-label="$options.i18n.title"
    size="small"
    icon="stop"
    category="secondary"
    variant="danger"
    @click="onClick"
  />
</template>
