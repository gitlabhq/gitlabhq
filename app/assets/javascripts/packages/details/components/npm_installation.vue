<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { mapGetters, mapState } from 'vuex';
import { s__ } from '~/locale';
import InstallationTitle from '~/packages/details/components/installation_title.vue';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';
import { NpmManager, TrackingActions, TrackingLabels } from '../constants';

export default {
  name: 'NpmInstallation',
  components: {
    InstallationTitle,
    CodeInstruction,
    GlLink,
    GlSprintf,
  },
  data() {
    return {
      instructionType: 'npm',
    };
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
    showNpm() {
      return this.instructionType === 'npm';
    },
  },
  i18n: {
    helpText: s__(
      'PackageRegistry|You may also need to setup authentication using an auth token. %{linkStart}See the documentation%{linkEnd} to find out more.',
    ),
  },
  trackingActions: { ...TrackingActions },
  TrackingLabels,
  installOptions: [
    { value: 'npm', label: s__('PackageRegistry|Show NPM commands') },
    { value: 'yarn', label: s__('PackageRegistry|Show Yarn commands') },
  ],
};
</script>

<template>
  <div>
    <installation-title
      package-type="npm"
      :options="$options.installOptions"
      @change="instructionType = $event"
    />

    <code-instruction
      v-if="showNpm"
      :instruction="npmCommand"
      :copy-text="s__('PackageRegistry|Copy npm command')"
      :tracking-action="$options.trackingActions.COPY_NPM_INSTALL_COMMAND"
      :tracking-label="$options.TrackingLabels.CODE_INSTRUCTION"
    />

    <code-instruction
      v-else
      :instruction="yarnCommand"
      :copy-text="s__('PackageRegistry|Copy yarn command')"
      :tracking-action="$options.trackingActions.COPY_YARN_INSTALL_COMMAND"
      :tracking-label="$options.TrackingLabels.CODE_INSTRUCTION"
    />

    <h3 class="gl-font-lg">{{ __('Registry setup') }}</h3>

    <code-instruction
      v-if="showNpm"
      :instruction="npmSetup"
      :copy-text="s__('PackageRegistry|Copy npm setup command')"
      :tracking-action="$options.trackingActions.COPY_NPM_SETUP_COMMAND"
      :tracking-label="$options.TrackingLabels.CODE_INSTRUCTION"
    />

    <code-instruction
      v-else
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
