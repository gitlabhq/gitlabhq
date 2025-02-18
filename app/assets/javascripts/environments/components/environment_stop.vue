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
  <div
    v-gl-tooltip="{ id: $options.stopEnvironmentTooltipId }"
    :title="title"
    :tabindex="isLoadingState ? 0 : null"
    class="gl-relative -gl-ml-[1px]"
  >
    <gl-button
      v-gl-modal-directive="'stop-environment-modal'"
      :loading="isLoadingState"
      :aria-label="title"
      :class="{ 'gl-pointer-events-none': isLoadingState }"
      class="!gl-rounded-none"
      size="small"
      icon="stop"
      category="secondary"
      variant="danger"
      @click="onClick"
    />
  </div>
</template>
