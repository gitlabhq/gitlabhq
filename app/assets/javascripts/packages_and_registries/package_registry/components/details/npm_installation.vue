<script>
import { GlLink, GlSprintf, GlFormRadioGroup } from '@gitlab/ui';
import { s__ } from '~/locale';

import InstallationTitle from '~/packages_and_registries/package_registry/components/details/installation_title.vue';
import {
  TRACKING_ACTION_COPY_NPM_INSTALL_COMMAND,
  TRACKING_ACTION_COPY_NPM_SETUP_COMMAND,
  TRACKING_ACTION_COPY_YARN_INSTALL_COMMAND,
  TRACKING_ACTION_COPY_YARN_SETUP_COMMAND,
  TRACKING_LABEL_CODE_INSTRUCTION,
  NPM_PACKAGE_MANAGER,
  YARN_PACKAGE_MANAGER,
  PROJECT_PACKAGE_ENDPOINT_TYPE,
  INSTANCE_PACKAGE_ENDPOINT_TYPE,
  NPM_HELP_PATH,
} from '~/packages_and_registries/package_registry/constants';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';

export default {
  name: 'NpmInstallation',
  components: {
    InstallationTitle,
    CodeInstruction,
    GlLink,
    GlSprintf,
    GlFormRadioGroup,
  },
  inject: ['npmInstanceUrl'],
  props: {
    packageEntity: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      instructionType: NPM_PACKAGE_MANAGER,
      packageEndpointType: INSTANCE_PACKAGE_ENDPOINT_TYPE,
    };
  },
  computed: {
    npmCommand() {
      return this.npmInstallationCommand(NPM_PACKAGE_MANAGER);
    },
    npmSetup() {
      return this.npmSetupCommand(NPM_PACKAGE_MANAGER, this.packageEndpointType);
    },
    yarnCommand() {
      return this.npmInstallationCommand(YARN_PACKAGE_MANAGER);
    },
    yarnSetupCommand() {
      return this.npmSetupCommand(YARN_PACKAGE_MANAGER, this.packageEndpointType);
    },
    showNpm() {
      return this.instructionType === NPM_PACKAGE_MANAGER;
    },
  },
  methods: {
    npmInstallationCommand(type) {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      const instruction = type === NPM_PACKAGE_MANAGER ? 'npm i' : 'yarn add';

      return `${instruction} ${this.packageEntity.name}`;
    },
    npmSetupCommand(type, endpointType) {
      const scope = this.packageEntity.name.substring(0, this.packageEntity.name.indexOf('/'));
      const npmPathForEndpoint =
        endpointType === INSTANCE_PACKAGE_ENDPOINT_TYPE
          ? this.npmInstanceUrl
          : this.packageEntity.npmUrl;

      if (type === NPM_PACKAGE_MANAGER) {
        return `echo ${scope}:registry=${npmPathForEndpoint}/ >> .npmrc`;
      }

      return `echo \\"${scope}:registry\\" \\"${npmPathForEndpoint}/\\" >> .yarnrc`;
    },
  },
  packageManagers: {
    NPM_PACKAGE_MANAGER,
  },
  tracking: {
    TRACKING_ACTION_COPY_NPM_INSTALL_COMMAND,
    TRACKING_ACTION_COPY_NPM_SETUP_COMMAND,
    TRACKING_ACTION_COPY_YARN_INSTALL_COMMAND,
    TRACKING_ACTION_COPY_YARN_SETUP_COMMAND,
    TRACKING_LABEL_CODE_INSTRUCTION,
  },
  i18n: {
    helpText: s__(
      'PackageRegistry|You may also need to setup authentication using an auth token. %{linkStart}See the documentation%{linkEnd} to find out more.',
    ),
  },
  links: { NPM_HELP_PATH },
  installOptions: [
    { value: NPM_PACKAGE_MANAGER, label: s__('PackageRegistry|Show NPM commands') },
    { value: YARN_PACKAGE_MANAGER, label: s__('PackageRegistry|Show Yarn commands') },
  ],
  packageEndpointTypeOptions: [
    { value: INSTANCE_PACKAGE_ENDPOINT_TYPE, text: s__('PackageRegistry|Instance-level') },
    { value: PROJECT_PACKAGE_ENDPOINT_TYPE, text: s__('PackageRegistry|Project-level') },
  ],
};
</script>

<template>
  <div>
    <installation-title
      :package-type="$options.packageManagers.NPM_PACKAGE_MANAGER"
      :options="$options.installOptions"
      @change="instructionType = $event"
    />

    <code-instruction
      v-if="showNpm"
      :instruction="npmCommand"
      :copy-text="s__('PackageRegistry|Copy npm command')"
      :tracking-action="$options.tracking.TRACKING_ACTION_COPY_NPM_INSTALL_COMMAND"
      :tracking-label="$options.tracking.TRACKING_LABEL_CODE_INSTRUCTION"
    />

    <code-instruction
      v-else
      :instruction="yarnCommand"
      :copy-text="s__('PackageRegistry|Copy yarn command')"
      :tracking-action="$options.tracking.TRACKING_ACTION_COPY_YARN_INSTALL_COMMAND"
      :tracking-label="$options.tracking.TRACKING_LABEL_CODE_INSTRUCTION"
    />

    <h3 class="gl-text-lg">{{ __('Registry setup') }}</h3>

    <gl-form-radio-group
      :options="$options.packageEndpointTypeOptions"
      :checked="packageEndpointType"
      @change="packageEndpointType = $event"
    />

    <code-instruction
      v-if="showNpm"
      :instruction="npmSetup"
      :copy-text="s__('PackageRegistry|Copy npm setup command')"
      :tracking-action="$options.tracking.TRACKING_ACTION_COPY_NPM_SETUP_COMMAND"
      :tracking-label="$options.tracking.TRACKING_LABEL_CODE_INSTRUCTION"
    />

    <code-instruction
      v-else
      :instruction="yarnSetupCommand"
      :copy-text="s__('PackageRegistry|Copy yarn setup command')"
      :tracking-action="$options.tracking.TRACKING_ACTION_COPY_YARN_SETUP_COMMAND"
      :tracking-label="$options.tracking.TRACKING_LABEL_CODE_INSTRUCTION"
    />

    <span class="gl-text-subtle">
      <gl-sprintf :message="$options.i18n.helpText">
        <template #link="{ content }">
          <gl-link :href="$options.links.NPM_HELP_PATH" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </span>
  </div>
</template>
