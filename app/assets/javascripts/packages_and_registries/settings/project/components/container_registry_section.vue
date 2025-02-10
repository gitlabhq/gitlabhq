<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { helpPagePath } from '~/helpers/help_page_helper';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import ContainerExpirationPolicy from '~/packages_and_registries/settings/project/components/container_expiration_policy.vue';
import ContainerProtectionRepositoryRules from '~/packages_and_registries/settings/project/components/container_protection_repository_rules.vue';
import ContainerProtectionTagRules from '~/packages_and_registries/settings/project/components/container_protection_tag_rules.vue';

export default {
  components: {
    GlLink,
    GlSprintf,
    ContainerExpirationPolicy,
    ContainerProtectionRepositoryRules,
    ContainerProtectionTagRules,
    SettingsBlock,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['isContainerRegistryMetadataDatabaseEnabled'],
  props: {
    expanded: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    showContainerProtectedTagsSettings() {
      return (
        this.glFeatures.containerRegistryProtectedTags &&
        this.isContainerRegistryMetadataDatabaseEnabled
      );
    },
  },
  containerRegistryHelpPath: helpPagePath('user/packages/container_registry/_index.md'),
};
</script>

<template>
  <settings-block
    id="container-registry-settings"
    :default-expanded="expanded"
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
        <container-protection-repository-rules />
        <container-protection-tag-rules v-if="showContainerProtectedTagsSettings" />
        <container-expiration-policy />
      </div>
    </template>
  </settings-block>
</template>
