<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import CodeInstruction from './code_instruction.vue';
import { TrackingActions } from '../constants';
import { mapGetters, mapState } from 'vuex';

export default {
  name: 'NugetInstallation',
  components: {
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
};
</script>

<template>
  <div>
    <h3 class="gl-font-lg">{{ __('Installation') }}</h3>
    <h4 class="gl-font-base">
      {{ s__('PackageRegistry|NuGet Command') }}
    </h4>
    <code-instruction
      :instruction="nugetInstallationCommand"
      :copy-text="s__('PackageRegistry|Copy NuGet Command')"
      :tracking-action="$options.trackingActions.COPY_NUGET_INSTALL_COMMAND"
    />
    <h3 class="gl-font-lg">{{ __('Registry setup') }}</h3>
    <h4 class="gl-font-base">
      {{ s__('PackageRegistry|Add NuGet Source') }}
    </h4>

    <code-instruction
      :instruction="nugetSetupCommand"
      :copy-text="s__('PackageRegistry|Copy NuGet Setup Command')"
      :tracking-action="$options.trackingActions.COPY_NUGET_SETUP_COMMAND"
    />
    <gl-sprintf :message="$options.i18n.helpText">
      <template #link="{ content }">
        <gl-link :href="nugetHelpPath" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>
