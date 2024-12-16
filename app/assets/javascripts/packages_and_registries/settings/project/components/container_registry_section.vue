<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { helpPagePath } from '~/helpers/help_page_helper';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import ContainerExpirationPolicy from '~/packages_and_registries/settings/project/components/container_expiration_policy.vue';
import ContainerProtectionRules from '~/packages_and_registries/settings/project/components/container_protection_rules.vue';

export default {
  components: {
    GlLink,
    GlSprintf,
    ContainerExpirationPolicy,
    ContainerProtectionRules,
    SettingsBlock,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    showProtectedContainersSettings() {
      return this.glFeatures.containerRegistryProtectedContainers;
    },
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
    <template #default>
      <div class="gl-flex gl-flex-col gl-gap-5">
        <container-protection-rules v-if="showProtectedContainersSettings" />
        <container-expiration-policy />
      </div>
    </template>
  </settings-block>
</template>
