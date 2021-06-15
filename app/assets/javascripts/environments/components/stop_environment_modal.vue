<script>
import { GlSprintf, GlTooltipDirective, GlModal } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import eventHub from '../event_hub';

export default {
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
  },

  computed: {
    primaryProps() {
      return {
        text: s__('Environments|Stop environment'),
        attributes: [{ variant: 'danger' }],
      };
    },
    cancelProps() {
      return {
        text: __('Cancel'),
      };
    },
  },

  methods: {
    onSubmit() {
      eventHub.$emit('stopEnvironment', this.environment);
    },
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
      <gl-sprintf :message="s__('Environments|Stopping %{environmentName}')">
        <template #environmentName>
          <span
            v-gl-tooltip
            :title="environment.name"
            class="gl-text-truncate gl-ml-2 gl-mr-2 gl-flex-grow-1"
          >
            {{ environment.name }}?
          </span>
        </template>
      </gl-sprintf>
    </template>

    <p>{{ s__('Environments|Are you sure you want to stop this environment?') }}</p>

    <div v-if="!environment.has_stop_action" class="warning_message">
      <p>
        <gl-sprintf
          :message="
            s__(`Environments|Note that this action will stop the environment,
        but it will %{emphasisStart}not%{emphasisEnd} have an effect on any existing deployment
        due to no “stop environment action” being defined
        in the %{ciConfigLinkStart}.gitlab-ci.yml%{ciConfigLinkEnd} file.`)
          "
        >
          <template #emphasis="{ content }">
            <strong>{{ content }}</strong>
          </template>
          <template #ciConfigLink="{ content }">
            <a href="https://docs.gitlab.com/ee/ci/yaml/" target="_blank" rel="noopener noreferrer">
              {{ content }}</a
            >
          </template>
        </gl-sprintf>
      </p>
      <a
        href="https://docs.gitlab.com/ee/ci/environments/#stopping-an-environment"
        target="_blank"
        rel="noopener noreferrer"
        >{{ s__('Environments|Learn more about stopping environments') }}</a
      >
    </div>
  </gl-modal>
</template>
