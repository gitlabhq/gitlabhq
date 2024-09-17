<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import InstallationTitle from '~/packages_and_registries/package_registry/components/details/installation_title.vue';
import {
  TRACKING_ACTION_COPY_CONAN_COMMAND,
  TRACKING_ACTION_COPY_CONAN_SETUP_COMMAND,
  TRACKING_LABEL_CODE_INSTRUCTION,
  CONAN_HELP_PATH,
} from '~/packages_and_registries/package_registry/constants';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';

export default {
  name: 'ConanInstallation',
  components: {
    InstallationTitle,
    CodeInstruction,
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
    conanInstallationCommand() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `conan install ${this.packageEntity.name} --remote=gitlab`;
    },
    conanSetupCommand() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `conan remote add gitlab ${this.packageEntity.conanUrl}`;
    },
  },
  i18n: {
    helpText: s__(
      'PackageRegistry|For more information on the Conan registry, %{linkStart}see the documentation%{linkEnd}.',
    ),
  },
  tracking: {
    TRACKING_ACTION_COPY_CONAN_COMMAND,
    TRACKING_ACTION_COPY_CONAN_SETUP_COMMAND,
    TRACKING_LABEL_CODE_INSTRUCTION,
  },
  links: { CONAN_HELP_PATH },
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
      :tracking-action="$options.tracking.TRACKING_ACTION_COPY_CONAN_COMMAND"
      :tracking-label="$options.tracking.TRACKING_LABEL_CODE_INSTRUCTION"
    />

    <h3 class="gl-text-lg">{{ __('Registry setup') }}</h3>

    <code-instruction
      :label="s__('PackageRegistry|Add Conan Remote')"
      :instruction="conanSetupCommand"
      :copy-text="s__('PackageRegistry|Copy Conan Setup Command')"
      :tracking-action="$options.tracking.TRACKING_ACTION_COPY_CONAN_SETUP_COMMAND"
      :tracking-label="$options.tracking.TRACKING_LABEL_CODE_INSTRUCTION"
    />
    <gl-sprintf :message="$options.i18n.helpText">
      <template #link="{ content }">
        <gl-link :href="$options.links.CONAN_HELP_PATH" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>
