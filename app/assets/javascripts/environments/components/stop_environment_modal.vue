<script>
import { GlSprintf, GlTooltipDirective, GlModal } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import eventHub from '../event_hub';
import stopEnvironmentMutation from '../graphql/mutations/stop_environment.mutation.graphql';

export default {
  environmentOnStopLink: helpPagePath('ci/yaml/_index.html', {
    anchor: 'environmenton_stop',
  }),
  stoppingEnvironmentDocsLink: helpPagePath('ci/environments/_index', {
    anchor: 'stopping-an-environment',
  }),

  id: 'stop-environment-modal',
  name: 'StopEnvironmentModal',

  components: {
    GlModal,
    GlSprintf,
  },

  directives: {
    GlTooltip: GlTooltipDirective,
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

  computed: {
    primaryProps() {
      return {
        text: s__('Environments|Stop environment'),
        attributes: { variant: 'danger' },
      };
    },
    cancelProps() {
      return {
        text: __('Cancel'),
      };
    },
    hasStopAction() {
      return this.graphql ? this.environment.hasStopAction : this.environment.has_stop_action;
    },
    stopMessage() {
      return this.hasStopAction
        ? this.$options.i18n.hasStopActionMessage
        : this.$options.i18n.noStopActionMessage;
    },
  },

  methods: {
    onSubmit() {
      if (this.graphql) {
        this.$apollo.mutate({
          mutation: stopEnvironmentMutation,
          variables: { environment: this.environment },
        });
      } else {
        eventHub.$emit('stopEnvironment', this.environment);
      }
    },
  },

  i18n: {
    noStopActionMessage: s__(
      'Environments|You are about to stop the environment %{environmentName}. The environment will be moved to the Stopped tab. There is no %{actionStopLinkStart}action:stop%{actionStopLinkEnd} defined for this environment, so your existing deployments will not be affected.',
    ),
    hasStopActionMessage: s__(
      'Environments|You are about to stop the environment %{environmentName}. Any deployments associated with this environment will no longer be accessible, and the environment will be moved to the Stopped tab.',
    ),
  },
};
</script>

<template>
  <gl-modal
    :modal-id="$options.id"
    :action-primary="primaryProps"
    :action-cancel="cancelProps"
    @primary="onSubmit"
  >
    <template #modal-title>
      <gl-sprintf :message="s__('Environments|Stop %{environmentName}')">
        <template #environmentName>
          <span v-gl-tooltip :title="environment.name" class="gl-grow gl-truncate">
            {{ environment.name }}?
          </span>
        </template>
      </gl-sprintf>
    </template>

    <p :class="!hasStopAction ? 'warning_message' : null">
      <gl-sprintf :message="stopMessage">
        <template #environmentName>
          <span>{{ environment.name }}</span>
        </template>

        <template v-if="!hasStopAction" #actionStopLink="{ content }">
          <a :href="$options.environmentOnStopLink" target="_blank" rel="noopener noreferrer">
            <span>{{ content }}</span>
          </a>
        </template>
      </gl-sprintf>

      <a
        :href="$options.stoppingEnvironmentDocsLink"
        target="_blank"
        rel="noopener noreferrer"
        class="gl-mt-5 gl-inline-block"
      >
        {{ s__('Environments|Learn more about stopping environments') }} </a
      >.
    </p>
  </gl-modal>
</template>
