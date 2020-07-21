<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import CodeInstruction from './code_instruction.vue';
import { TrackingActions, TrackingLabels } from '../constants';
import { mapGetters, mapState } from 'vuex';
import InstallationTabs from './installation_tabs.vue';

export default {
  name: 'ConanInstallation',
  components: {
    CodeInstruction,
    GlLink,
    GlSprintf,
    InstallationTabs,
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
  trackingLabel: TrackingLabels.CONAN_INSTALLATION,
};
</script>

<template>
  <installation-tabs :tracking-label="$options.trackingLabel">
    <template #installation>
      <p class="gl-mt-3 font-weight-bold">{{ s__('PackageRegistry|Conan Command') }}</p>
      <code-instruction
        :instruction="conanInstallationCommand"
        :copy-text="s__('PackageRegistry|Copy Conan Command')"
        class="js-conan-command"
        :tracking-action="$options.trackingActions.COPY_CONAN_COMMAND"
      />
    </template>

    <template #setup>
      <p class="gl-mt-3 font-weight-bold">
        {{ s__('PackageRegistry|Add Conan Remote') }}
      </p>
      <code-instruction
        :instruction="conanSetupCommand"
        :copy-text="s__('PackageRegistry|Copy Conan Setup Command')"
        class="js-conan-setup"
        :tracking-action="$options.trackingActions.COPY_CONAN_SETUP_COMMAND"
      />
      <gl-sprintf :message="$options.i18n.helpText">
        <template #link="{ content }">
          <gl-link :href="conanHelpPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
  </installation-tabs>
</template>
