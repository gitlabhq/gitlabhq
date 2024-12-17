<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import DependencyProxyPackagesSettings from 'ee_component/packages_and_registries/settings/project/components/dependency_proxy_packages_settings.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import PackagesCleanupPolicy from '~/packages_and_registries/settings/project/components/packages_cleanup_policy.vue';
import PackagesProtectionRules from '~/packages_and_registries/settings/project/components/packages_protection_rules.vue';

export default {
  components: {
    DependencyProxyPackagesSettings,
    GlLink,
    GlSprintf,
    PackagesCleanupPolicy,
    PackagesProtectionRules,
    SettingsBlock,
  },
  inject: ['showDependencyProxySettings'],
  supportedPackageManagersHelpPath: helpPagePath(
    'user/packages/package_registry/supported_package_managers.md',
  ),
};
</script>

<template>
  <settings-block id="package-registry-settings" :title="s__('PackageRegistry|Package registry')">
    <template #description>
      <gl-sprintf
        :message="
          s__(
            'PackageRegistry|With the GitLab package registry, you can use GitLab as a private or public registry for a variety of %{linkStart}supported package managers%{linkEnd}. You can publish and share packages, which can be consumed as a dependency in downstream projects.',
          )
        "
      >
        <template #link="{ content }">
          <gl-link :href="$options.supportedPackageManagersHelpPath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
    <template #default>
      <div class="gl-flex gl-flex-col gl-gap-5">
        <packages-protection-rules />
        <dependency-proxy-packages-settings v-if="showDependencyProxySettings" />
        <packages-cleanup-policy />
      </div>
    </template>
  </settings-block>
</template>
