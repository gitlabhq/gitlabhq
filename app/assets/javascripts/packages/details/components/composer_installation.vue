<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import CodeInstruction from './code_instruction.vue';
import { TrackingActions } from '../constants';
import { mapGetters, mapState } from 'vuex';

export default {
  name: 'ComposerInstallation',
  components: {
    CodeInstruction,
    GlLink,
    GlSprintf,
  },
  computed: {
    ...mapState(['composerHelpPath']),
    ...mapGetters(['composerRegistryInclude', 'composerPackageInclude']),
  },
  i18n: {
    registryInclude: s__('PackageRegistry|composer.json registry include'),
    copyRegistryInclude: s__('PackageRegistry|Copy registry include'),
    packageInclude: s__('PackageRegistry|composer.json require package include'),
    copyPackageInclude: s__('PackageRegistry|Copy require package include'),
    infoLine: s__(
      'PackageRegistry|For more information on Composer packages in GitLab, %{linkStart}see the documentation.%{linkEnd}',
    ),
  },
  trackingActions: { ...TrackingActions },
};
</script>

<template>
  <div>
    <h3 class="gl-font-lg">{{ __('Installation') }}</h3>
    <h4 class="gl-font-base" data-testid="registry-include-title">
      {{ $options.i18n.registryInclude }}
    </h4>

    <code-instruction
      :instruction="composerRegistryInclude"
      :copy-text="$options.i18n.copyRegistryInclude"
      :tracking-action="$options.trackingActions.COPY_COMPOSER_REGISTRY_INCLUDE_COMMAND"
    />
    <h4 class="gl-font-base" data-testid="package-include-title">
      {{ $options.i18n.packageInclude }}
    </h4>
    <code-instruction
      :instruction="composerPackageInclude"
      :copy-text="$options.i18n.copyPackageInclude"
      :tracking-action="$options.trackingActions.COPY_COMPOSER_PACKAGE_INCLUDE_COMMAND"
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
