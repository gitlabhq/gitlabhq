<script>
import { GlAlert } from '@gitlab/ui';
import { n__ } from '~/locale';
import PackagesSettings from '~/packages_and_registries/settings/group/components/packages_settings.vue';
import PackagesForwardingSettings from '~/packages_and_registries/settings/group/components/packages_forwarding_settings.vue';
import DependencyProxySettings from '~/packages_and_registries/settings/group/components/dependency_proxy_settings.vue';

import getGroupPackagesSettingsQuery from '~/packages_and_registries/settings/group/graphql/queries/get_group_packages_settings.query.graphql';

export default {
  name: 'GroupSettingsApp',
  components: {
    GlAlert,
    PackagesSettings,
    PackagesForwardingSettings,
    DependencyProxySettings,
  },
  inject: ['groupPath'],
  apollo: {
    group: {
      query: getGroupPackagesSettingsQuery,
      variables() {
        return {
          fullPath: this.groupPath,
        };
      },
    },
  },
  data() {
    return {
      group: {},
      alertMessage: null,
    };
  },
  computed: {
    packageSettings() {
      return this.group?.packageSettings || {};
    },
    dependencyProxySettings() {
      return this.group?.dependencyProxySetting || {};
    },
    dependencyProxyImageTtlPolicy() {
      return this.group?.dependencyProxyImageTtlPolicy || {};
    },
    isLoading() {
      return this.$apollo.queries.group.loading;
    },
  },
  methods: {
    dismissAlert() {
      this.alertMessage = null;
    },
    handleSuccess(amount = 1) {
      const successMessage = n__(
        'Setting saved successfully',
        'Settings saved successfully',
        amount,
      );
      this.$toast.show(successMessage);
      this.dismissAlert();
    },
    handleError(amount = 1) {
      const errorMessage = n__(
        'An error occurred while saving the setting',
        'An error occurred while saving the settings',
        amount,
      );
      this.alertMessage = errorMessage;
    },
  },
};
</script>

<template>
  <div data-testid="packages-and-registries-group-settings">
    <gl-alert v-if="alertMessage" variant="warning" class="gl-mt-4" @dismiss="dismissAlert">
      {{ alertMessage }}
    </gl-alert>

    <packages-settings
      :package-settings="packageSettings"
      :is-loading="isLoading"
      @success="handleSuccess(2)"
      @error="handleError(2)"
    />

    <packages-forwarding-settings
      :forward-settings="packageSettings"
      @success="handleSuccess(2)"
      @error="handleError(2)"
    />

    <dependency-proxy-settings
      :dependency-proxy-settings="dependencyProxySettings"
      :dependency-proxy-image-ttl-policy="dependencyProxyImageTtlPolicy"
      :is-loading="isLoading"
      @success="handleSuccess"
      @error="handleError"
    />
  </div>
</template>
