<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { mapGetters, mapState } from 'vuex';
import { s__ } from '~/locale';
import InstallationTitle from '~/packages/details/components/installation_title.vue';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';
import { TrackingActions, TrackingLabels } from '../constants';

export default {
  name: 'ComposerInstallation',
  components: {
    InstallationTitle,
    CodeInstruction,
    GlLink,
    GlSprintf,
  },
  computed: {
    ...mapState(['composerHelpPath']),
    ...mapGetters(['composerRegistryInclude', 'composerPackageInclude', 'groupExists']),
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
  trackingActions: { ...TrackingActions },
  TrackingLabels,
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
      :tracking-action="$options.trackingActions.COPY_COMPOSER_REGISTRY_INCLUDE_COMMAND"
      :tracking-label="$options.TrackingLabels.CODE_INSTRUCTION"
      data-testid="registry-include"
    />

    <code-instruction
      :label="$options.i18n.packageInclude"
      :instruction="composerPackageInclude"
      :copy-text="$options.i18n.copyPackageInclude"
      :tracking-action="$options.trackingActions.COPY_COMPOSER_PACKAGE_INCLUDE_COMMAND"
      :tracking-label="$options.TrackingLabels.CODE_INSTRUCTION"
      data-testid="package-include"
    />
    <span data-testid="help-text">
      <gl-sprintf :message="$options.i18n.infoLine">
        <template #link="{ content }">
          <gl-link :href="composerHelpPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </span>
  </div>
</template>
