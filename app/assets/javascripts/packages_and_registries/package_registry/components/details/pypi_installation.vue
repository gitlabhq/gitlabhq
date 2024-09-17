<script>
import { GlFormGroup, GlLink, GlSprintf } from '@gitlab/ui';

import { s__ } from '~/locale';
import InstallationTitle from '~/packages_and_registries/package_registry/components/details/installation_title.vue';
import {
  PERSONAL_ACCESS_TOKEN_HELP_URL,
  TRACKING_ACTION_COPY_PIP_INSTALL_COMMAND,
  TRACKING_ACTION_COPY_PYPI_SETUP_COMMAND,
  TRACKING_LABEL_CODE_INSTRUCTION,
  PYPI_HELP_PATH,
} from '~/packages_and_registries/package_registry/constants';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';

export default {
  name: 'PyPiInstallation',
  components: {
    InstallationTitle,
    CodeInstruction,
    GlFormGroup,
    GlLink,
    GlSprintf,
  },
  props: {
    packageEntity: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isPrivatePackage() {
      return !this.packageEntity.publicPackage;
    },
    pypiPipCommand() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `pip install ${this.packageEntity.name} --index-url ${this.packageEntity.pypiUrl}`;
    },
    pypiSetupCommand() {
      return `[gitlab]
repository = ${this.packageEntity.pypiSetupUrl}
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
    tokenText: s__(`PackageRegistry|You will need a %{linkStart}personal access token%{linkEnd}.`),
    setupText: s__(
      `PackageRegistry|If you haven't already done so, you will need to add the below to your %{codeStart}.pypirc%{codeEnd} file.`,
    ),
    helpText: s__(
      'PackageRegistry|For more information on the PyPi registry, %{linkStart}see the documentation%{linkEnd}.',
    ),
  },
  links: {
    PERSONAL_ACCESS_TOKEN_HELP_URL,
    PYPI_HELP_PATH,
  },
  installOptions: [{ value: 'pypi', label: s__('PackageRegistry|Show PyPi commands') }],
};
</script>

<template>
  <div>
    <installation-title package-type="pypi" :options="$options.installOptions" />

    <gl-form-group id="installation-pip-command-group">
      <code-instruction
        id="installation-pip-command"
        :label="s__('PackageRegistry|Pip Command')"
        :instruction="pypiPipCommand"
        :copy-text="s__('PackageRegistry|Copy Pip command')"
        data-testid="pip-command"
        :tracking-action="$options.tracking.TRACKING_ACTION_COPY_PIP_INSTALL_COMMAND"
        :tracking-label="$options.tracking.TRACKING_LABEL_CODE_INSTRUCTION"
      />
      <template v-if="isPrivatePackage" #description>
        <gl-sprintf :message="$options.i18n.tokenText">
          <template #link="{ content }">
            <gl-link
              :href="$options.links.PERSONAL_ACCESS_TOKEN_HELP_URL"
              data-testid="access-token-link"
              >{{ content }}</gl-link
            >
          </template>
        </gl-sprintf>
      </template>
    </gl-form-group>

    <h3 class="gl-text-lg">{{ __('Registry setup') }}</h3>
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
        <gl-link
          :href="$options.links.PYPI_HELP_PATH"
          target="_blank"
          data-testid="pypi-docs-link"
          >{{ content }}</gl-link
        >
      </template>
    </gl-sprintf>
  </div>
</template>
