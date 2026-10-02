<script>
import { GlSprintf, GlTooltipDirective, GlModal, GlFormCheckbox } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
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
    GlFormCheckbox,
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
  },

  data() {
    return {
      forceStop: false,
    };
  },

  computed: {
    isEnvironmentStopping() {
      return this.environment.state === 'stopping';
    },
    hasStopAction() {
      return this.environment.hasStopAction;
    },
    // An environment already in `stopping` can only be moved on by a forced stop.
    shouldForceStop() {
      return this.isEnvironmentStopping || this.forceStop;
    },
    showForceStopOption() {
      return this.hasStopAction && !this.isEnvironmentStopping;
    },
    modalTitle() {
      return this.isEnvironmentStopping
        ? s__('Environments|Force stop %{environmentName}')
        : s__('Environments|Stop %{environmentName}');
    },
    primaryProps() {
      return {
        text: this.shouldForceStop
          ? s__('Environments|Force stop environment')
          : s__('Environments|Stop environment'),
        attributes: { variant: 'danger' },
      };
    },
    cancelProps() {
      return {
        text: __('Cancel'),
      };
    },
    stopMessage() {
      if (this.isEnvironmentStopping) {
        return this.$options.i18n.stoppingMessage;
      }

      return this.hasStopAction
        ? this.$options.i18n.hasStopActionMessage
        : this.$options.i18n.noStopActionMessage;
    },
  },

  methods: {
    onSubmit() {
      this.$apollo.mutate({
        mutation: stopEnvironmentMutation,
        variables: { environment: this.environment, force: this.shouldForceStop },
      });
    },
    onHidden() {
      this.forceStop = false;
    },
  },

  i18n: {
    noStopActionMessage: s__(
      'Environments|You are about to stop the environment %{environmentName}. The environment will be moved to the Stopped tab. There is no %{actionStopLinkStart}action:stop%{actionStopLinkEnd} defined for this environment, so your existing deployments will not be affected.',
    ),
    hasStopActionMessage: s__(
      'Environments|You are about to stop the environment %{environmentName}. Any deployments associated with this environment will no longer be accessible, and the environment will be moved to the Stopped tab.',
    ),
    stoppingMessage: s__(
      'Environments|The environment %{environmentName} is currently stopping. Force stopping marks it as stopped immediately and moves it to the Stopped tab, without running or waiting for its %{actionStopLinkStart}action:stop%{actionStopLinkEnd} job. Resources deployed to this environment might not be cleaned up.',
    ),
    forceStopHelp: s__(
      'Environments|Skip the %{actionStopLinkStart}action:stop%{actionStopLinkEnd} job and mark the environment as stopped immediately. Resources deployed to this environment might not be cleaned up.',
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
    @hidden="onHidden"
  >
    <template #modal-title>
      <gl-sprintf :message="modalTitle">
        <template #environmentName>
          <span v-gl-tooltip :title="environment.name" class="gl-grow gl-truncate">
            {{ environment.name }}?
          </span>
        </template>
      </gl-sprintf>
    </template>

    <p :class="!hasStopAction ? 'warning_message' : null" data-testid="stop-environment-message">
      <gl-sprintf :message="stopMessage">
        <template #environmentName>
          <span>{{ environment.name }}</span>
        </template>

        <template #actionStopLink="{ content }">
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

    <gl-form-checkbox v-if="showForceStopOption" v-model="forceStop">
      {{ s__('Environments|Force stop') }}
      <template #help>
        <gl-sprintf :message="$options.i18n.forceStopHelp">
          <template #actionStopLink="{ content }">
            <a :href="$options.environmentOnStopLink" target="_blank" rel="noopener noreferrer">
              <span>{{ content }}</span>
            </a>
          </template>
        </gl-sprintf>
      </template>
    </gl-form-checkbox>
  </gl-modal>
</template>
