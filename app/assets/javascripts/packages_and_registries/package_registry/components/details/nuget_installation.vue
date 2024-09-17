<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import InstallationTitle from '~/packages_and_registries/package_registry/components/details/installation_title.vue';
import {
  TRACKING_ACTION_COPY_NUGET_INSTALL_COMMAND,
  TRACKING_ACTION_COPY_NUGET_SETUP_COMMAND,
  TRACKING_LABEL_CODE_INSTRUCTION,
  NUGET_HELP_PATH,
} from '~/packages_and_registries/package_registry/constants';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';

export default {
  name: 'NugetInstallation',
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
    nugetInstallationCommand() {
      return `nuget install ${this.packageEntity.name} -Source "GitLab"`;
    },
    nugetSetupCommand() {
      return `nuget source Add -Name "GitLab" -Source "${this.packageEntity.nugetUrl}" -UserName <your_username> -Password <your_token>`;
    },
  },
  tracking: {
    TRACKING_ACTION_COPY_NUGET_INSTALL_COMMAND,
    TRACKING_ACTION_COPY_NUGET_SETUP_COMMAND,
    TRACKING_LABEL_CODE_INSTRUCTION,
  },
  i18n: {
    helpText: s__(
      'PackageRegistry|For more information on the NuGet registry, %{linkStart}see the documentation%{linkEnd}.',
    ),
  },
  links: { NUGET_HELP_PATH },
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
      :tracking-action="$options.tracking.TRACKING_ACTION_COPY_NUGET_INSTALL_COMMAND"
      :tracking-label="$options.tracking.TRACKING_LABEL_CODE_INSTRUCTION"
    />
    <h3 class="gl-text-lg">{{ __('Registry setup') }}</h3>

    <code-instruction
      :label="s__('PackageRegistry|Add NuGet Source')"
      :instruction="nugetSetupCommand"
      :copy-text="s__('PackageRegistry|Copy NuGet Setup Command')"
      :tracking-action="$options.tracking.TRACKING_ACTION_COPY_NUGET_SETUP_COMMAND"
      :tracking-label="$options.tracking.TRACKING_LABEL_CODE_INSTRUCTION"
    />
    <gl-sprintf :message="$options.i18n.helpText">
      <template #link="{ content }">
        <gl-link :href="$options.links.NUGET_HELP_PATH" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>
