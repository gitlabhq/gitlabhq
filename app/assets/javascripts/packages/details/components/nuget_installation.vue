<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { mapGetters, mapState } from 'vuex';
import { s__ } from '~/locale';
import InstallationTitle from '~/packages/details/components/installation_title.vue';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';
import { TrackingActions, TrackingLabels } from '../constants';

export default {
  name: 'NugetInstallation',
  components: {
    InstallationTitle,
    CodeInstruction,
    GlLink,
    GlSprintf,
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
  TrackingLabels,
  installOptions: [{ value: 'nuget', label: s__('PackageRegistry|Show Nuget commands') }],
};
</script>

<template>
  <div>
    <installation-title package-type="nuget" :options="$options.installOptions" />

    <code-instruction
      :label="s__('PackageRegistry|NuGet Command')"
      :instruction="nugetInstallationCommand"
      :copy-text="s__('PackageRegistry|Copy NuGet Command')"
      :tracking-action="$options.trackingActions.COPY_NUGET_INSTALL_COMMAND"
      :tracking-label="$options.TrackingLabels.CODE_INSTRUCTION"
    />
    <h3 class="gl-font-lg">{{ __('Registry setup') }}</h3>

    <code-instruction
      :label="s__('PackageRegistry|Add NuGet Source')"
      :instruction="nugetSetupCommand"
      :copy-text="s__('PackageRegistry|Copy NuGet Setup Command')"
      :tracking-action="$options.trackingActions.COPY_NUGET_SETUP_COMMAND"
      :tracking-label="$options.TrackingLabels.CODE_INSTRUCTION"
    />
    <gl-sprintf :message="$options.i18n.helpText">
      <template #link="{ content }">
        <gl-link :href="nugetHelpPath" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>
