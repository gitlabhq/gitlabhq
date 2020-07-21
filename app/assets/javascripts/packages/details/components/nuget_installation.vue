<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import CodeInstruction from './code_instruction.vue';
import { TrackingActions, TrackingLabels } from '../constants';
import { mapGetters, mapState } from 'vuex';
import InstallationTabs from './installation_tabs.vue';

export default {
  name: 'NugetInstallation',
  components: {
    CodeInstruction,
    GlLink,
    GlSprintf,
    InstallationTabs,
  },
  computed: {
    ...mapState(['nugetHelpPath']),
    ...mapGetters(['nugetInstallationCommand', 'nugetSetupCommand']),
  },
  i18n: {
    helpText: s__(
      'PackageRegistry|For more information on the NuGet registry, %{linkStart}see the documentation%{linkEnd}.',
    ),
  },
  trackingActions: { ...TrackingActions },
  trackingLabel: TrackingLabels.NUGET_INSTALLATION,
};
</script>

<template>
  <installation-tabs :tracking-label="$options.trackingLabel">
    <template #installation>
      <p class="gl-mt-3 font-weight-bold">{{ s__('PackageRegistry|NuGet Command') }}</p>
      <code-instruction
        :instruction="nugetInstallationCommand"
        :copy-text="s__('PackageRegistry|Copy NuGet Command')"
        class="js-nuget-command"
        :tracking-action="$options.trackingActions.COPY_NUGET_INSTALL_COMMAND"
      />
    </template>

    <template #setup>
      <p class="gl-mt-3 font-weight-bold">
        {{ s__('PackageRegistry|Add NuGet Source') }}
      </p>
      <code-instruction
        :instruction="nugetSetupCommand"
        :copy-text="s__('PackageRegistry|Copy NuGet Setup Command')"
        class="js-nuget-setup"
        :tracking-action="$options.trackingActions.COPY_NUGET_SETUP_COMMAND"
      />
      <gl-sprintf :message="$options.i18n.helpText">
        <template #link="{ content }">
          <gl-link :href="nugetHelpPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
  </installation-tabs>
</template>
