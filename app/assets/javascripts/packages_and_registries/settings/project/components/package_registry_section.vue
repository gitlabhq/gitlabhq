<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  components: {
    GlLink,
    GlSprintf,
    SettingsBlock,
  },
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
  </settings-block>
</template>
