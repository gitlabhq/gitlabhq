<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
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
    CodeInstruction,
    GlAlert,
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
  },
  i18n: {
    registryInclude: s__('PackageRegistry|Add composer registry'),
    copyRegistryInclude: s__('PackageRegistry|Copy registry include'),
    packageInclude: s__('PackageRegistry|Install package version'),
    copyPackageInclude: s__('PackageRegistry|Copy require package include'),
    infoLine: s__(
      'PackageRegistry|For more information on Composer packages in GitLab, %{linkStart}see the documentation.%{linkEnd}',
    ),
    noGroupListUrlWarning: s__(
      'PackageRegistry|Composer packages are installed at the group level, but there is no group associated with this project.',
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
};
</script>

<template>
  <div v-if="!groupListUrl" data-testid="error-root-node">
    <gl-alert variant="warning" :dismissible="false">
      {{ $options.i18n.noGroupListUrlWarning }}
    </gl-alert>
  </div>
  <div v-else data-testid="root-node">
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
