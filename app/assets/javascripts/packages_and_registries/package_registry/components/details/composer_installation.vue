<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import InstallationTitle from '~/packages_and_registries/package_registry/components/details/installation_title.vue';
import {
  TRACKING_ACTION_COPY_COMPOSER_REGISTRY_INCLUDE_COMMAND,
  TRACKING_ACTION_COPY_COMPOSER_PACKAGE_INCLUDE_COMMAND,
  TRACKING_LABEL_CODE_INSTRUCTION,
  COMPOSER_HELP_PATH,
} from '~/packages_and_registries/package_registry/constants';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';

export default {
  name: 'ComposerInstallation',
  components: {
    InstallationTitle,
    CodeInstruction,
    GlLink,
    GlSprintf,
  },
  inject: ['groupListUrl'],
  props: {
    packageEntity: {
      type: Object,
      required: true,
    },
  },
  computed: {
    composerRegistryInclude() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `composer config repositories.${this.packageEntity.composerConfigRepositoryUrl} '{"type": "composer", "url": "${this.packageEntity.composerUrl}"}'`;
    },
    composerPackageInclude() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `composer req ${[this.packageEntity.name]}:${this.packageEntity.version}`;
    },
    groupExists() {
      return this.groupListUrl?.length > 0;
    },
  },
  i18n: {
    registryInclude: s__('PackageRegistry|Add composer registry'),
    copyRegistryInclude: s__('PackageRegistry|Copy registry include'),
    packageInclude: s__('PackageRegistry|Install package version'),
    copyPackageInclude: s__('PackageRegistry|Copy require package include'),
    infoLine: s__(
      'PackageRegistry|For more information on Composer packages in GitLab, %{linkStart}see the documentation.%{linkEnd}',
    ),
  },
  tracking: {
    TRACKING_ACTION_COPY_COMPOSER_REGISTRY_INCLUDE_COMMAND,
    TRACKING_ACTION_COPY_COMPOSER_PACKAGE_INCLUDE_COMMAND,
    TRACKING_LABEL_CODE_INSTRUCTION,
  },
  links: {
    COMPOSER_HELP_PATH,
  },
  installOptions: [{ value: 'composer', label: s__('PackageRegistry|Show Composer commands') }],
};
</script>

<template>
  <div v-if="groupExists" data-testid="root-node">
    <installation-title package-type="composer" :options="$options.installOptions" />

    <code-instruction
      :label="$options.i18n.registryInclude"
      :instruction="composerRegistryInclude"
      :copy-text="$options.i18n.copyRegistryInclude"
      :tracking-action="$options.tracking.TRACKING_ACTION_COPY_COMPOSER_REGISTRY_INCLUDE_COMMAND"
      :tracking-label="$options.tracking.TRACKING_LABEL_CODE_INSTRUCTION"
      data-testid="registry-include"
    />

    <code-instruction
      :label="$options.i18n.packageInclude"
      :instruction="composerPackageInclude"
      :copy-text="$options.i18n.copyPackageInclude"
      :tracking-action="$options.tracking.TRACKING_ACTION_COPY_COMPOSER_PACKAGE_INCLUDE_COMMAND"
      :tracking-label="$options.tracking.TRACKING_LABEL_CODE_INSTRUCTION"
      data-testid="package-include"
    />
    <span data-testid="help-text">
      <gl-sprintf :message="$options.i18n.infoLine">
        <template #link="{ content }">
          <gl-link :href="$options.links.COMPOSER_HELP_PATH" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </span>
  </div>
</template>
