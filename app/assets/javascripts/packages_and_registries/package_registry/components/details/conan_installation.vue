<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { mapGetters, mapState } from 'vuex';
import { s__ } from '~/locale';
import { TrackingActions, TrackingLabels } from '~/packages/details/constants';
import InstallationTitle from '~/packages_and_registries/package_registry/components/details/installation_title.vue';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';

export default {
  name: 'ConanInstallation',
  components: {
    InstallationTitle,
    CodeInstruction,
    GlLink,
    GlSprintf,
  },
  computed: {
    ...mapState(['conanHelpPath']),
    ...mapGetters(['conanInstallationCommand', 'conanSetupCommand']),
  },
  i18n: {
    helpText: s__(
      'PackageRegistry|For more information on the Conan registry, %{linkStart}see the documentation%{linkEnd}.',
    ),
  },
  trackingActions: { ...TrackingActions },
  TrackingLabels,
  installOptions: [{ value: 'conan', label: s__('PackageRegistry|Show Conan commands') }],
};
</script>

<template>
  <div>
    <installation-title package-type="conan" :options="$options.installOptions" />

    <code-instruction
      :label="s__('PackageRegistry|Conan Command')"
      :instruction="conanInstallationCommand"
      :copy-text="s__('PackageRegistry|Copy Conan Command')"
      :tracking-action="$options.trackingActions.COPY_CONAN_COMMAND"
      :tracking-label="$options.TrackingLabels.CODE_INSTRUCTION"
    />

    <h3 class="gl-font-lg">{{ __('Registry setup') }}</h3>

    <code-instruction
      :label="s__('PackageRegistry|Add Conan Remote')"
      :instruction="conanSetupCommand"
      :copy-text="s__('PackageRegistry|Copy Conan Setup Command')"
      :tracking-action="$options.trackingActions.COPY_CONAN_SETUP_COMMAND"
      :tracking-label="$options.TrackingLabels.CODE_INSTRUCTION"
    />
    <gl-sprintf :message="$options.i18n.helpText">
      <template #link="{ content }">
        <gl-link :href="conanHelpPath" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>
