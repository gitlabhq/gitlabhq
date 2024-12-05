<script>
import { GlAlert } from '@gitlab/ui';
import DependencyProxyPackagesSettings from 'ee_component/packages_and_registries/settings/project/components/dependency_proxy_packages_settings.vue';
import { historyReplaceState } from '~/lib/utils/common_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import {
  SHOW_SETUP_SUCCESS_ALERT,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
} from '~/packages_and_registries/settings/project/constants';
import ContainerExpirationPolicy from '~/packages_and_registries/settings/project/components/container_expiration_policy.vue';
import ContainerProtectionRules from '~/packages_and_registries/settings/project/components/container_protection_rules.vue';
import PackagesCleanupPolicy from '~/packages_and_registries/settings/project/components/packages_cleanup_policy.vue';
import PackagesProtectionRules from '~/packages_and_registries/settings/project/components/packages_protection_rules.vue';
import MetadataDatabaseAlert from '~/packages_and_registries/shared/components/container_registry_metadata_database_alert.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import PackageRegistrySection from '~/packages_and_registries/settings/project/components/package_registry_section.vue';
import ContainerRegistrySection from '~/packages_and_registries/settings/project/components/container_registry_section.vue';

export default {
  components: {
    ContainerExpirationPolicy,
    ContainerProtectionRules,
    ContainerRegistrySection,
    DependencyProxyPackagesSettings,
    GlAlert,
    MetadataDatabaseAlert,
    PackageRegistrySection,
    PackagesCleanupPolicy,
    PackagesProtectionRules,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: [
    'showContainerRegistrySettings',
    'showPackageRegistrySettings',
    'showDependencyProxySettings',
    'isContainerRegistryMetadataDatabaseEnabled',
  ],
  i18n: {
    UPDATE_SETTINGS_SUCCESS_MESSAGE,
  },
  data() {
    return {
      showAlert: false,
    };
  },
  computed: {
    showProtectedContainersSettings() {
      return (
        this.glFeatures.containerRegistryProtectedContainers && this.showContainerRegistrySettings
      );
    },
    showReorganizedSettings() {
      return this.glFeatures.reorganizeProjectLevelRegistrySettings;
    },
  },
  mounted() {
    this.checkAlert();
  },
  methods: {
    checkAlert() {
      const showAlert = getParameterByName(SHOW_SETUP_SUCCESS_ALERT);

      if (showAlert) {
        this.showAlert = true;
        const cleanUrl = window.location.href.split('?')[0];
        historyReplaceState(cleanUrl);
      }
    },
  },
};
</script>

<template>
  <div
    data-testid="packages-and-registries-project-settings"
    class="js-hide-when-nothing-matches-search"
  >
    <gl-alert
      v-if="showAlert"
      variant="success"
      class="gl-mt-5"
      dismissible
      @dismiss="showAlert = false"
    >
      {{ $options.i18n.UPDATE_SETTINGS_SUCCESS_MESSAGE }}
    </gl-alert>
    <template v-if="showReorganizedSettings">
      <package-registry-section v-if="showPackageRegistrySettings" />
      <container-registry-section v-if="showContainerRegistrySettings" />
    </template>
    <template v-else>
      <metadata-database-alert v-if="!isContainerRegistryMetadataDatabaseEnabled" class="gl-mt-5" />
      <template v-if="showPackageRegistrySettings">
        <packages-protection-rules />
        <packages-cleanup-policy />
      </template>
      <container-protection-rules v-if="showProtectedContainersSettings" />
      <container-expiration-policy v-if="showContainerRegistrySettings" />
      <dependency-proxy-packages-settings v-if="showDependencyProxySettings" />
    </template>
  </div>
</template>
