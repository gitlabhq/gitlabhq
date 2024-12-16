<script>
import { GlAlert, GlCard } from '@gitlab/ui';
import {
  FETCH_SETTINGS_ERROR_MESSAGE,
  PACKAGES_CLEANUP_POLICY_TITLE,
  PACKAGES_CLEANUP_POLICY_DESCRIPTION,
} from '~/packages_and_registries/settings/project/constants';
import packagesCleanupPolicyQuery from '~/packages_and_registries/settings/project/graphql/queries/get_packages_cleanup_policy.query.graphql';
import SettingsSection from '~/vue_shared/components/settings/settings_section.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import PackagesCleanupPolicyForm from './packages_cleanup_policy_form.vue';

export default {
  components: {
    SettingsSection,
    GlAlert,
    GlCard,
    PackagesCleanupPolicyForm,
  },
  mixins: [glFeatureFlagsMixin()],
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
  computed: {
    featureFlagEnabled() {
      return this.glFeatures.reorganizeProjectLevelRegistrySettings;
    },
  },
};
</script>

<template>
  <gl-card v-if="featureFlagEnabled">
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
  <settings-section v-else :heading="$options.i18n.PACKAGES_CLEANUP_POLICY_TITLE">
    <template #description>
      <span data-testid="description">
        {{ $options.i18n.PACKAGES_CLEANUP_POLICY_DESCRIPTION }}
      </span>
    </template>

    <gl-alert v-if="fetchSettingsError" variant="warning" :dismissible="false">
      {{ $options.i18n.FETCH_SETTINGS_ERROR_MESSAGE }}
    </gl-alert>
    <packages-cleanup-policy-form
      v-else
      v-model="packagesCleanupPolicy"
      :is-loading="$apollo.queries.packagesCleanupPolicy.loading"
    />
  </settings-section>
</template>
