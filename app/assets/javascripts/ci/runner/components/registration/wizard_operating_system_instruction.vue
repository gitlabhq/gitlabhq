<script>
import { GlIcon, GlLink, GlSprintf, GlBadge } from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { EXECUTORS_HELP_URL, SERVICE_COMMANDS_HELP_URL } from '../../constants';
import PlatformsDrawer from './platforms_drawer.vue';
import CliCommand from './cli_command.vue';
import { commandPrompt, registerCommand, runCommand } from './utils';

export default {
  name: 'OperatingSystemRegistrationInstructions',
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
    GlBadge,
    CrudComponent,
    CliCommand,
    PlatformsDrawer,
  },
  props: {
    token: {
      type: String,
      required: true,
    },
    platform: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isDrawerOpen: false,
    };
  },
  computed: {
    commandPrompt() {
      return commandPrompt({ platform: this.platform });
    },
    registerCommand() {
      return registerCommand({
        platform: this.platform,
        token: this.token,
      });
    },
    runCommand() {
      return runCommand({ platform: this.platform });
    },
  },
  methods: {
    onToggleDrawer(val = !this.isDrawerOpen) {
      this.isDrawerOpen = val;
    },
  },
  EXECUTORS_HELP_URL,
  SERVICE_COMMANDS_HELP_URL,
};
</script>
<template>
  <crud-component :is-collapsible="true" :collapsed="true">
    <template #title>
      {{ title }}
      <gl-badge variant="neutral">{{ s__('Runners|Operating System') }}</gl-badge>
    </template>
    <p>
      <gl-sprintf
        :message="
          s__(
            'Runners|GitLab Runner must be installed before you can register a runner. %{linkStart}How do I install GitLab Runner?%{linkEnd}',
          )
        "
      >
        <template #link="{ content }">
          <gl-link data-testid="how-to-install-btn" @click="onToggleDrawer()">{{
            content
          }}</gl-link>
        </template>
      </gl-sprintf>
    </p>

    <section class="gl-mt-6" data-testid="step-1">
      <h3 class="gl-heading-3">{{ s__('Runners|Step 1') }}</h3>
      <p>
        {{
          s__(
            'Runners|Copy and paste the following command into your command line to register the runner.',
          )
        }}
      </p>
      <cli-command :prompt="commandPrompt" :command="registerCommand" />
    </section>
    <section class="gl-mt-6" data-testid="step-2">
      <h3 class="gl-heading-3">{{ s__('Runners|Step 2') }}</h3>
      <p>
        <gl-sprintf
          :message="
            s__(
              'Runners|Choose an executor when prompted by the command line. Executors run builds in different environments. %{linkStart}Not sure which one to select?%{linkEnd}',
            )
          "
        >
          <template #link="{ content }">
            <gl-link
              :href="$options.EXECUTORS_HELP_URL"
              target="_blank"
              data-testid="executors-help-link"
            >
              {{ content }} <gl-icon name="external-link" />
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
    </section>
    <section class="gl-mt-6" data-testid="step-3">
      <h3 class="gl-heading-3">{{ s__('Runners|Step 3 (optional)') }}</h3>
      <p>{{ s__('Runners|Manually verify that the runner is available to pick up jobs.') }}</p>
      <cli-command :prompt="commandPrompt" :command="runCommand" />
      <p>
        <gl-sprintf
          :message="
            s__(
              'Runners|This may not be needed if you manage your runner as a %{linkStart}system or user service%{linkEnd}.',
            )
          "
        >
          <template #link="{ content }">
            <gl-link
              :href="$options.SERVICE_COMMANDS_HELP_URL"
              target="_blank"
              data-testid="service-commands-help-link"
            >
              {{ content }} <gl-icon name="external-link" />
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
    </section>

    <platforms-drawer :platform="platform" :open="isDrawerOpen" @close="onToggleDrawer(false)" />
  </crud-component>
</template>
