<script>
import { GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';
import PackagesSettings from '~/packages_and_registries/settings/group/components/packages_settings.vue';
import PackagesForwardingSettings from '~/packages_and_registries/settings/group/components/packages_forwarding_settings.vue';
import DependencyProxySettings from '~/packages_and_registries/settings/group/components/dependency_proxy_settings.vue';
import glAbilitiesMixin from '~/vue_shared/mixins/gl_abilities_mixin';
import getGroupPackagesSettingsQuery from '~/packages_and_registries/settings/group/graphql/queries/get_group_packages_settings.query.graphql';

export default {
  name: 'GroupSettingsApp',
  components: {
    GlAlert,
    PackagesSettings,
    PackagesForwardingSettings,
    DependencyProxySettings,
  },
  mixins: [glAbilitiesMixin()],
  inject: ['groupPath'],
  apollo: {
    group: {
      query: getGroupPackagesSettingsQuery,
      variables() {
        return {
          fullPath: this.groupPath,
        };
      },
      context: {
        batchKey: 'GroupPackagesSettings',
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
    handleSuccess() {
      const successMessage = __('Settings saved successfully.');
      this.$toast.show(successMessage);
      this.dismissAlert();
    },
    handleError() {
      const errorMessage = __('An error occurred while saving the settings.');
      this.alertMessage = errorMessage;
    },
  },
};
</script>

<template>
  <div
    data-testid="packages-and-registries-group-settings"
    class="js-hide-when-nothing-matches-search"
  >
    <gl-alert v-if="alertMessage" variant="warning" class="gl-mt-4" @dismiss="dismissAlert">
      {{ alertMessage }}
    </gl-alert>

    <slot
      name="virtual-registries-setting"
      :handle-success="handleSuccess"
      :handle-error="handleError"
    ></slot>

    <packages-settings
      id="packages-settings"
      :package-settings="packageSettings"
      :is-loading="isLoading"
      @success="handleSuccess"
      @error="handleError"
    />

    <packages-forwarding-settings
      id="packages-forwarding-settings"
      :forward-settings="packageSettings"
      @success="handleSuccess"
      @error="handleError"
    />

    <dependency-proxy-settings
      v-if="glAbilities.adminDependencyProxy"
      id="dependency-proxy-settings"
      :dependency-proxy-settings="dependencyProxySettings"
      :dependency-proxy-image-ttl-policy="dependencyProxyImageTtlPolicy"
      :is-loading="isLoading"
      @success="handleSuccess"
      @error="handleError"
    />
  </div>
</template>
