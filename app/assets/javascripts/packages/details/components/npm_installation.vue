<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import CodeInstruction from './code_instruction.vue';
import { NpmManager, TrackingActions, TrackingLabels } from '../constants';
import { mapGetters, mapState } from 'vuex';
import InstallationTabs from './installation_tabs.vue';

export default {
  name: 'NpmInstallation',
  components: {
    CodeInstruction,
    GlLink,
    GlSprintf,
    InstallationTabs,
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
  trackingLabel: TrackingLabels.NPM_INSTALLATION,
};
</script>

<template>
  <installation-tabs :tracking-label="$options.trackingLabel">
    <template #installation>
      <p class="gl-mt-3 font-weight-bold">{{ s__('PackageRegistry|npm') }}</p>
      <code-instruction
        :instruction="npmCommand"
        :copy-text="s__('PackageRegistry|Copy npm command')"
        class="js-npm-install"
        :tracking-action="$options.trackingActions.COPY_NPM_INSTALL_COMMAND"
      />

      <p class="gl-mt-3 font-weight-bold">{{ s__('PackageRegistry|yarn') }}</p>
      <code-instruction
        :instruction="yarnCommand"
        :copy-text="s__('PackageRegistry|Copy yarn command')"
        class="js-yarn-install"
        :tracking-action="$options.trackingActions.COPY_YARN_INSTALL_COMMAND"
      />
    </template>

    <template #setup>
      <p class="gl-mt-3 font-weight-bold">{{ s__('PackageRegistry|npm') }}</p>
      <code-instruction
        :instruction="npmSetup"
        :copy-text="s__('PackageRegistry|Copy npm setup command')"
        class="js-npm-setup"
        :tracking-action="$options.trackingActions.COPY_NPM_SETUP_COMMAND"
      />

      <p class="gl-mt-3 font-weight-bold">{{ s__('PackageRegistry|yarn') }}</p>
      <code-instruction
        :instruction="yarnSetupCommand"
        :copy-text="s__('PackageRegistry|Copy yarn setup command')"
        class="js-yarn-setup"
        :tracking-action="$options.trackingActions.COPY_YARN_SETUP_COMMAND"
      />

      <gl-sprintf :message="$options.i18n.helpText">
        <template #link="{ content }">
          <gl-link :href="npmHelpPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
  </installation-tabs>
</template>
