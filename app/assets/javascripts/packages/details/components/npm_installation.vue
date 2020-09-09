<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { mapGetters, mapState } from 'vuex';
import { s__ } from '~/locale';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';
import { NpmManager, TrackingActions, TrackingLabels } from '../constants';

export default {
  name: 'NpmInstallation',
  components: {
    CodeInstruction,
    GlLink,
    GlSprintf,
  },
  computed: {
    ...mapState(['npmHelpPath']),
    ...mapGetters(['npmInstallationCommand', 'npmSetupCommand']),
    npmCommand() {
      return this.npmInstallationCommand(NpmManager.NPM);
    },
    npmSetup() {
      return this.npmSetupCommand(NpmManager.NPM);
    },
    yarnCommand() {
      return this.npmInstallationCommand(NpmManager.YARN);
    },
    yarnSetupCommand() {
      return this.npmSetupCommand(NpmManager.YARN);
    },
  },
  i18n: {
    helpText: s__(
      'PackageRegistry|You may also need to setup authentication using an auth token. %{linkStart}See the documentation%{linkEnd} to find out more.',
    ),
  },
  trackingActions: { ...TrackingActions },
  TrackingLabels,
};
</script>

<template>
  <div>
    <h3 class="gl-font-lg">{{ __('Installation') }}</h3>

    <code-instruction
      :label="s__('PackageRegistry|npm command')"
      :instruction="npmCommand"
      :copy-text="s__('PackageRegistry|Copy npm command')"
      :tracking-action="$options.trackingActions.COPY_NPM_INSTALL_COMMAND"
      :tracking-label="$options.TrackingLabels.CODE_INSTRUCTION"
    />

    <code-instruction
      :label="s__('PackageRegistry|yarn command')"
      :instruction="yarnCommand"
      :copy-text="s__('PackageRegistry|Copy yarn command')"
      :tracking-action="$options.trackingActions.COPY_YARN_INSTALL_COMMAND"
      :tracking-label="$options.TrackingLabels.CODE_INSTRUCTION"
    />

    <h3 class="gl-font-lg">{{ __('Registry setup') }}</h3>

    <code-instruction
      :label="s__('PackageRegistry|npm command')"
      :instruction="npmSetup"
      :copy-text="s__('PackageRegistry|Copy npm setup command')"
      :tracking-action="$options.trackingActions.COPY_NPM_SETUP_COMMAND"
      :tracking-label="$options.TrackingLabels.CODE_INSTRUCTION"
    />

    <code-instruction
      :label="s__('PackageRegistry|yarn command')"
      :instruction="yarnSetupCommand"
      :copy-text="s__('PackageRegistry|Copy yarn setup command')"
      :tracking-action="$options.trackingActions.COPY_YARN_SETUP_COMMAND"
      :tracking-label="$options.TrackingLabels.CODE_INSTRUCTION"
    />

    <gl-sprintf :message="$options.i18n.helpText">
      <template #link="{ content }">
        <gl-link :href="npmHelpPath" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>
