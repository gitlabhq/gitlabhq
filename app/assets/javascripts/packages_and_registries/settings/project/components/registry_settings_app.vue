<script>
import { GlAlert } from '@gitlab/ui';
import { historyReplaceState } from '~/lib/utils/common_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import {
  SHOW_SETUP_SUCCESS_ALERT,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
} from '~/packages_and_registries/settings/project/constants';
import ContainerExpirationPolicy from '~/packages_and_registries/settings/project/components/container_expiration_policy.vue';
import ContainerProtectionRules from '~/packages_and_registries/settings/project/components/container_protection_rules.vue';
import PackagesCleanupPolicy from '~/packages_and_registries/settings/project/components/packages_cleanup_policy.vue';
import MetadataDatabaseAlert from '~/packages_and_registries/shared/components/container_registry_metadata_database_alert.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    ContainerExpirationPolicy,
    ContainerProtectionRules,
    DependencyProxyPackagesSettings: () =>
      import(
        'ee_component/packages_and_registries/settings/project/components/dependency_proxy_packages_settings.vue'
      ),
    GlAlert,
    MetadataDatabaseAlert,
    PackagesCleanupPolicy,
    PackagesProtectionRules: () =>
      import('~/packages_and_registries/settings/project/components/packages_protection_rules.vue'),
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
    showProtectedPackagesSettings() {
      return this.showPackageRegistrySettings && this.glFeatures.packagesProtectedPackages;
    },
    showProtectedContainersSettings() {
      return (
        this.glFeatures.containerRegistryProtectedContainers && this.showContainerRegistrySettings
      );
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
  <div data-testid="packages-and-registries-project-settings">
    <metadata-database-alert v-if="!isContainerRegistryMetadataDatabaseEnabled" class="gl-mt-5" />
    <gl-alert
      v-if="showAlert"
      variant="success"
      class="gl-mt-5"
      dismissible
      @dismiss="showAlert = false"
    >
      {{ $options.i18n.UPDATE_SETTINGS_SUCCESS_MESSAGE }}
    </gl-alert>
    <packages-protection-rules v-if="showProtectedPackagesSettings" />
    <packages-cleanup-policy v-if="showPackageRegistrySettings" />
    <container-protection-rules v-if="showProtectedContainersSettings" />
    <container-expiration-policy v-if="showContainerRegistrySettings" />
    <dependency-proxy-packages-settings v-if="showDependencyProxySettings" />
  </div>
</template>
