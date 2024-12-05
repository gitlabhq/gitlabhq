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
  containerRegistryHelpPath: helpPagePath('user/packages/container_registry/index.md'),
};
</script>

<template>
  <settings-block
    id="container-registry-settings"
    :title="s__('ContainerRegistry|Container registry')"
  >
    <template #description>
      <gl-sprintf
        :message="
          s__(
            'ContainerRegistry|The %{linkStart}GitLab Container Registry%{linkEnd} is a secure and private registry for container images. It’s built on open source software and completely integrated within GitLab. Use GitLab CI/CD to create and publish images. Use the GitLab API to manage the registry across groups and projects.',
          )
        "
      >
        <template #link="{ content }">
          <gl-link :href="$options.containerRegistryHelpPath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
  </settings-block>
</template>
