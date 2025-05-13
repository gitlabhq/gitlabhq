<script>
import { GlAlert } from '@gitlab/ui';
import {
  FETCH_SETTINGS_ERROR_MESSAGE,
  PACKAGES_CLEANUP_POLICY_TITLE,
  PACKAGES_CLEANUP_POLICY_DESCRIPTION,
} from '~/packages_and_registries/settings/project/constants';
import SettingsSubSection from '~/vue_shared/components/settings/settings_sub_section.vue';
import packagesCleanupPolicyQuery from '~/packages_and_registries/settings/project/graphql/queries/get_packages_cleanup_policy.query.graphql';
import PackagesCleanupPolicyForm from './packages_cleanup_policy_form.vue';

export default {
  components: {
    GlAlert,
    PackagesCleanupPolicyForm,
    SettingsSubSection,
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
  <settings-sub-section
    :heading="$options.i18n.PACKAGES_CLEANUP_POLICY_TITLE"
    :description="$options.i18n.PACKAGES_CLEANUP_POLICY_DESCRIPTION"
  >
    <gl-alert v-if="fetchSettingsError" variant="warning" :dismissible="false">
      {{ $options.i18n.FETCH_SETTINGS_ERROR_MESSAGE }}
    </gl-alert>
    <packages-cleanup-policy-form
      v-else
      v-model="packagesCleanupPolicy"
      :is-loading="$apollo.queries.packagesCleanupPolicy.loading"
    />
  </settings-sub-section>
</template>
