<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import CodeInstruction from './code_instruction.vue';
import { NpmManager, TrackingActions } from '../constants';
import { mapGetters, mapState } from 'vuex';

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
};
</script>

<template>
  <div>
    <h3 class="gl-font-lg">{{ __('Installation') }}</h3>
    <h4 class="gl-font-base">{{ s__('PackageRegistry|npm command') }}</h4>

    <code-instruction
      :instruction="npmCommand"
      :copy-text="s__('PackageRegistry|Copy npm command')"
      :tracking-action="$options.trackingActions.COPY_NPM_INSTALL_COMMAND"
    />

    <h4 class="gl-font-base">{{ s__('PackageRegistry|yarn command') }}</h4>
    <code-instruction
      :instruction="yarnCommand"
      :copy-text="s__('PackageRegistry|Copy yarn command')"
      :tracking-action="$options.trackingActions.COPY_YARN_INSTALL_COMMAND"
    />

    <h3 class="gl-font-lg">{{ __('Registry setup') }}</h3>

    <h4 class="gl-font-base">{{ s__('PackageRegistry|npm command') }}</h4>
    <code-instruction
      :instruction="npmSetup"
      :copy-text="s__('PackageRegistry|Copy npm setup command')"
      :tracking-action="$options.trackingActions.COPY_NPM_SETUP_COMMAND"
    />

    <h4 class="gl-font-base">{{ s__('PackageRegistry|yarn command') }}</h4>
    <code-instruction
      :instruction="yarnSetupCommand"
      :copy-text="s__('PackageRegistry|Copy yarn setup command')"
      :tracking-action="$options.trackingActions.COPY_YARN_SETUP_COMMAND"
    />

    <gl-sprintf :message="$options.i18n.helpText">
      <template #link="{ content }">
        <gl-link :href="npmHelpPath" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>
