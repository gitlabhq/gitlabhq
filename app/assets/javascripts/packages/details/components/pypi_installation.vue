<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import CodeInstruction from './code_instruction.vue';
import { TrackingActions } from '../constants';
import { mapGetters, mapState } from 'vuex';

export default {
  name: 'PyPiInstallation',
  components: {
    CodeInstruction,
    GlLink,
    GlSprintf,
  },
  computed: {
    ...mapState(['pypiHelpPath']),
    ...mapGetters(['pypiPipCommand', 'pypiSetupCommand']),
  },
  i18n: {
    setupText: s__(
      `PackageRegistry|If you haven't already done so, you will need to add the below to your %{codeStart}.pypirc%{codeEnd} file.`,
    ),
    helpText: s__(
      'PackageRegistry|For more information on the PyPi registry, %{linkStart}see the documentation%{linkEnd}.',
    ),
  },
  trackingActions: { ...TrackingActions },
};
</script>

<template>
  <div>
    <h3 class="gl-font-lg">{{ __('Installation') }}</h3>

    <h4 class="gl-font-base">
      {{ s__('PackageRegistry|Pip Command') }}
    </h4>

    <code-instruction
      :instruction="pypiPipCommand"
      :copy-text="s__('PackageRegistry|Copy Pip command')"
      data-testid="pip-command"
      :tracking-action="$options.trackingActions.COPY_PIP_INSTALL_COMMAND"
    />

    <h3 class="gl-font-lg">{{ __('Registry setup') }}</h3>
    <p>
      <gl-sprintf :message="$options.i18n.setupText">
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
      </gl-sprintf>
    </p>

    <code-instruction
      :instruction="pypiSetupCommand"
      :copy-text="s__('PackageRegistry|Copy .pypirc content')"
      data-testid="pypi-setup-content"
      multiline
      :tracking-action="$options.trackingActions.COPY_PYPI_SETUP_COMMAND"
    />
    <gl-sprintf :message="$options.i18n.helpText">
      <template #link="{ content }">
        <gl-link :href="pypiHelpPath" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>
