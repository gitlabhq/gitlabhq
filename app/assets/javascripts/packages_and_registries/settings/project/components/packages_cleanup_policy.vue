<script>
import { GlAlert, GlCard } from '@gitlab/ui';
import {
  FETCH_SETTINGS_ERROR_MESSAGE,
  PACKAGES_CLEANUP_POLICY_TITLE,
  PACKAGES_CLEANUP_POLICY_DESCRIPTION,
} from '~/packages_and_registries/settings/project/constants';
import packagesCleanupPolicyQuery from '~/packages_and_registries/settings/project/graphql/queries/get_packages_cleanup_policy.query.graphql';
import PackagesCleanupPolicyForm from './packages_cleanup_policy_form.vue';

export default {
  components: {
    GlAlert,
    GlCard,
    PackagesCleanupPolicyForm,
  },
  inject: ['projectPath'],
  i18n: {
    FETCH_SETTINGS_ERROR_MESSAGE,
    PACKAGES_CLEANUP_POLICY_TITLE,
    PACKAGES_CLEANUP_POLICY_DESCRIPTION,
  },
  apollo: {
    packagesCleanupPolicy: {
      query: packagesCleanupPolicyQuery,
      context: {
        batchKey: 'PackageRegistryProjectSettings',
      },
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update: (data) => data.project?.packagesCleanupPolicy || {},
      error(e) {
        this.fetchSettingsError = e;
      },
    },
  },
  data() {
    return {
      fetchSettingsError: false,
      packagesCleanupPolicy: {},
    };
  },
};
</script>

<template>
  <gl-card>
    <template #header>
      <h2 class="gl-m-0 gl-inline-flex gl-items-center gl-text-base gl-font-bold gl-leading-normal">
        {{ $options.i18n.PACKAGES_CLEANUP_POLICY_TITLE }}
      </h2>
    </template>
    <template #default>
      <p class="gl-text-subtle" data-testid="description">
        {{ $options.i18n.PACKAGES_CLEANUP_POLICY_DESCRIPTION }}
      </p>
      <gl-alert v-if="fetchSettingsError" variant="warning" :dismissible="false">
        {{ $options.i18n.FETCH_SETTINGS_ERROR_MESSAGE }}
      </gl-alert>
      <packages-cleanup-policy-form
        v-else
        v-model="packagesCleanupPolicy"
        :is-loading="$apollo.queries.packagesCleanupPolicy.loading"
      />
    </template>
  </gl-card>
</template>
