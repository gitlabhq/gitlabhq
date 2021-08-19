<script>
import { GlLink, GlSprintf } from '@gitlab/ui';

import { s__ } from '~/locale';
import InstallationTitle from '~/packages_and_registries/package_registry/components/details/installation_title.vue';
import {
  TRACKING_ACTION_COPY_PIP_INSTALL_COMMAND,
  TRACKING_ACTION_COPY_PYPI_SETUP_COMMAND,
  TRACKING_LABEL_CODE_INSTRUCTION,
} from '~/packages_and_registries/package_registry/constants';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';

export default {
  name: 'PyPiInstallation',
  components: {
    InstallationTitle,
    CodeInstruction,
    GlLink,
    GlSprintf,
  },
  inject: ['pypiHelpPath', 'pypiPath', 'pypiSetupPath'],
  props: {
    packageEntity: {
      type: Object,
      required: true,
    },
  },
  computed: {
    pypiPipCommand() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `pip install ${this.packageEntity.name} --extra-index-url ${this.pypiPath}`;
    },
    pypiSetupCommand() {
      return `[gitlab]
repository = ${this.pypiSetupPath}
username = __token__
password = <your personal access token>`;
    },
  },
  tracking: {
    TRACKING_ACTION_COPY_PIP_INSTALL_COMMAND,
    TRACKING_ACTION_COPY_PYPI_SETUP_COMMAND,
    TRACKING_LABEL_CODE_INSTRUCTION,
  },
  i18n: {
    setupText: s__(
      `PackageRegistry|If you haven't already done so, you will need to add the below to your %{codeStart}.pypirc%{codeEnd} file.`,
    ),
    helpText: s__(
      'PackageRegistry|For more information on the PyPi registry, %{linkStart}see the documentation%{linkEnd}.',
    ),
  },
  installOptions: [{ value: 'pypi', label: s__('PackageRegistry|Show PyPi commands') }],
};
</script>

<template>
  <div>
    <installation-title package-type="pypi" :options="$options.installOptions" />

    <code-instruction
      :label="s__('PackageRegistry|Pip Command')"
      :instruction="pypiPipCommand"
      :copy-text="s__('PackageRegistry|Copy Pip command')"
      data-testid="pip-command"
      :tracking-action="$options.tracking.TRACKING_ACTION_COPY_PIP_INSTALL_COMMAND"
      :tracking-label="$options.tracking.TRACKING_LABEL_CODE_INSTRUCTION"
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
      :tracking-action="$options.tracking.TRACKING_ACTION_COPY_PYPI_SETUP_COMMAND"
      :tracking-label="$options.tracking.TRACKING_LABEL_CODE_INSTRUCTION"
    />
    <gl-sprintf :message="$options.i18n.helpText">
      <template #link="{ content }">
        <gl-link :href="pypiHelpPath" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>
