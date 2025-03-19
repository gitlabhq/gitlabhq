<script>
/**
 * Renders the stop "button" that allows stop an environment.
 * Used in environments table.
 */

import { GlTooltipDirective, GlButton, GlModalDirective } from '@gitlab/ui';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { s__ } from '~/locale';
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
    stopTitle: s__('Environments|Stop environment'),
    stoppingTitle: s__('Environments|Stopping environment'),
  },
  data() {
    return {
      isLoading: false,
      isEnvironmentStopping: false,
    };
  },
  computed: {
    isLoadingState() {
      return this.environment.state === 'stopping' || this.isEnvironmentStopping || this.isLoading;
    },
    title() {
      return this.isLoadingState ? this.$options.i18n.stoppingTitle : this.$options.i18n.stopTitle;
    },
  },
  methods: {
    onClick() {
      this.$root.$emit(BV_HIDE_TOOLTIP, this.$options.stopEnvironmentTooltipId);
      this.$apollo.mutate({
        mutation: setEnvironmentToStopMutation,
        variables: { environment: this.environment },
      });
    },
  },
  stopEnvironmentTooltipId: 'stop-environment-button-tooltip',
};
</script>
<template>
  <gl-button
    v-gl-modal-directive="'stop-environment-modal'"
    v-gl-tooltip="{ id: $options.stopEnvironmentTooltipId }"
    :title="title"
    :tabindex="isLoadingState ? 0 : null"
    :loading="isLoadingState"
    :aria-label="title"
    :class="{ 'gl-pointer-events-none': isLoadingState }"
    size="small"
    icon="stop"
    variant="danger"
    @click="onClick"
  />
</template>
