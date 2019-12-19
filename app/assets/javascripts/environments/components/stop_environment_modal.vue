<script>
/* eslint-disable @gitlab/vue-i18n/no-bare-strings */
import { GlTooltipDirective } from '@gitlab/ui';
import DeprecatedModal2 from '~/vue_shared/components/deprecated_modal_2.vue';
import { s__, sprintf } from '~/locale';
import eventHub from '../event_hub';

export default {
  id: 'stop-environment-modal',
  name: 'StopEnvironmentModal',

  components: {
    GlModal: DeprecatedModal2,
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
    noStopActionMessage() {
      return sprintf(
        s__(
          `Environments|Note that this action will stop the environment,
        but it will %{emphasisStart}not%{emphasisEnd} have an effect on any existing deployment
        due to no “stop environment action” being defined
        in the %{ciConfigLinkStart}.gitlab-ci.yml%{ciConfigLinkEnd} file.`,
        ),
        {
          emphasisStart: '<strong>',
          emphasisEnd: '</strong>',
          ciConfigLinkStart:
            '<a href="https://docs.gitlab.com/ee/ci/yaml/" target="_blank" rel="noopener noreferrer">',
          ciConfigLinkEnd: '</a>',
        },
        false,
      );
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
    :id="$options.id"
    :footer-primary-button-text="s__('Environments|Stop environment')"
    footer-primary-button-variant="danger"
    @submit="onSubmit"
  >
    <template slot="header">
      <h4 class="modal-title d-flex mw-100">
        Stopping
        <span v-gl-tooltip :title="environment.name" class="text-truncate ml-1 mr-1 flex-fill">{{
          environment.name
        }}</span>
        ?
      </h4>
    </template>

    <p>{{ s__('Environments|Are you sure you want to stop this environment?') }}</p>

    <div v-if="!environment.has_stop_action" class="warning_message">
      <p v-html="noStopActionMessage"></p>
      <a
        href="https://docs.gitlab.com/ee/ci/environments.html#stopping-an-environment"
        target="_blank"
        rel="noopener noreferrer"
        >{{ s__('Environments|Learn more about stopping environments') }}</a
      >
    </div>
  </gl-modal>
</template>
