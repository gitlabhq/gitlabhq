<script>
import { GlAlert, GlSprintf } from '@gitlab/ui';
import {
  FETCH_SETTINGS_ERROR_MESSAGE,
  PACKAGES_CLEANUP_POLICY_TITLE,
  PACKAGES_CLEANUP_POLICY_DESCRIPTION,
} from '~/packages_and_registries/settings/project/constants';
import packagesCleanupPolicyQuery from '~/packages_and_registries/settings/project/graphql/queries/get_packages_cleanup_policy.query.graphql';
import SettingsSection from '~/vue_shared/components/settings/settings_section.vue';

import PackagesCleanupPolicyForm from './packages_cleanup_policy_form.vue';

export default {
  components: {
    SettingsSection,
    GlAlert,
    GlSprintf,
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
  <settings-section :heading="$options.i18n.PACKAGES_CLEANUP_POLICY_TITLE">
    <template #description>
      <span data-testid="description">
        <gl-sprintf :message="$options.i18n.PACKAGES_CLEANUP_POLICY_DESCRIPTION" />
      </span>
    </template>

    <gl-alert v-if="fetchSettingsError" variant="warning" :dismissible="false">
      <gl-sprintf :message="$options.i18n.FETCH_SETTINGS_ERROR_MESSAGE" />
    </gl-alert>
    <packages-cleanup-policy-form
      v-else
      v-model="packagesCleanupPolicy"
      :is-loading="$apollo.queries.packagesCleanupPolicy.loading"
    />
  </settings-section>
</template>
