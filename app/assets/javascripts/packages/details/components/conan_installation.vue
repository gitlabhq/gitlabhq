<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import CodeInstruction from './code_instruction.vue';
import { TrackingActions } from '../constants';
import { mapGetters, mapState } from 'vuex';

export default {
  name: 'ConanInstallation',
  components: {
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
};
</script>

<template>
  <div>
    <h3 class="gl-font-lg">{{ __('Installation') }}</h3>
    <h4 class="gl-font-base">
      {{ s__('PackageRegistry|Conan Command') }}
    </h4>

    <code-instruction
      :instruction="conanInstallationCommand"
      :copy-text="s__('PackageRegistry|Copy Conan Command')"
      :tracking-action="$options.trackingActions.COPY_CONAN_COMMAND"
    />

    <h3 class="gl-font-lg">{{ __('Registry setup') }}</h3>
    <h4 class="gl-font-base">
      {{ s__('PackageRegistry|Add Conan Remote') }}
    </h4>
    <code-instruction
      :instruction="conanSetupCommand"
      :copy-text="s__('PackageRegistry|Copy Conan Setup Command')"
      :tracking-action="$options.trackingActions.COPY_CONAN_SETUP_COMMAND"
    />
    <gl-sprintf :message="$options.i18n.helpText">
      <template #link="{ content }">
        <gl-link :href="conanHelpPath" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>
