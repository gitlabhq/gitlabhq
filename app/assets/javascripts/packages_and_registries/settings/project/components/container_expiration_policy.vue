<script>
import { GlAlert, GlSprintf, GlLink, GlCard, GlButton, GlSkeletonLoader } from '@gitlab/ui';
import {
  CONTAINER_CLEANUP_POLICY_TITLE,
  CONTAINER_CLEANUP_POLICY_DESCRIPTION,
  CONTAINER_CLEANUP_POLICY_EDIT_RULES,
  CONTAINER_CLEANUP_POLICY_SET_RULES,
  FETCH_SETTINGS_ERROR_MESSAGE,
  UNAVAILABLE_FEATURE_TITLE,
  UNAVAILABLE_FEATURE_INTRO_TEXT,
  UNAVAILABLE_USER_FEATURE_TEXT,
  UNAVAILABLE_ADMIN_FEATURE_TEXT,
} from '~/packages_and_registries/settings/project/constants';
import expirationPolicyEnabledQuery from '~/packages_and_registries/settings/project/graphql/queries/get_expiration_policy_enabled.query.graphql';
import ContainerExpirationPolicyEnabledText from '~/packages_and_registries/settings/project/components/container_expiration_policy_enabled_text.vue';

export default {
  components: {
    ContainerExpirationPolicyEnabledText,
    GlAlert,
    GlSprintf,
    GlLink,
    GlCard,
    GlButton,
    GlSkeletonLoader,
  },
  inject: [
    'projectPath',
    'isAdmin',
    'adminSettingsPath',
    'enableHistoricEntries',
    'helpPagePath',
    'cleanupSettingsPath',
  ],
  i18n: {
    CONTAINER_CLEANUP_POLICY_TITLE,
    CONTAINER_CLEANUP_POLICY_DESCRIPTION,
    CONTAINER_CLEANUP_POLICY_EDIT_RULES,
    CONTAINER_CLEANUP_POLICY_SET_RULES,
    UNAVAILABLE_FEATURE_TITLE,
    UNAVAILABLE_FEATURE_INTRO_TEXT,
    FETCH_SETTINGS_ERROR_MESSAGE,
  },
  apollo: {
    containerTagsExpirationPolicy: {
      query: expirationPolicyEnabledQuery,
      context: {
        batchKey: 'ContainerRegistryProjectSettings',
      },
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update: (data) => data.project?.containerTagsExpirationPolicy,
      error(e) {
        this.fetchSettingsError = e;
      },
    },
  },
  data() {
    return {
      fetchSettingsError: false,
      containerTagsExpirationPolicy: null,
    };
  },
  computed: {
    isCleanupEnabled() {
      return this.containerTagsExpirationPolicy?.enabled ?? false;
    },
    isEnabled() {
      return this.containerTagsExpirationPolicy || this.enableHistoricEntries;
    },
    isLoading() {
      return this.$apollo.queries.containerTagsExpirationPolicy.loading;
    },
    showDisabledFormMessage() {
      return !this.isEnabled && !this.fetchSettingsError;
    },
    unavailableFeatureMessage() {
      return this.isAdmin ? UNAVAILABLE_ADMIN_FEATURE_TEXT : UNAVAILABLE_USER_FEATURE_TEXT;
    },
    cleanupRulesButtonText() {
      return this.isCleanupEnabled
        ? this.$options.i18n.CONTAINER_CLEANUP_POLICY_EDIT_RULES
        : this.$options.i18n.CONTAINER_CLEANUP_POLICY_SET_RULES;
    },
  },
};
</script>

<template>
  <gl-card data-testid="container-expiration-policy-project-settings">
    <template #header>
      <header class="gl-flex gl-flex-wrap gl-justify-between">
        <h2
          class="gl-m-0 gl-inline-flex gl-items-center gl-text-base gl-font-bold gl-leading-normal"
        >
          {{ $options.i18n.CONTAINER_CLEANUP_POLICY_TITLE }}
        </h2>
        <gl-button
          v-if="isEnabled"
          data-testid="rules-button"
          :href="cleanupSettingsPath"
          :loading="isLoading"
          category="secondary"
          size="small"
          variant="confirm"
        >
          {{ cleanupRulesButtonText }}
        </gl-button>
      </header>
    </template>
    <template #default>
      <p class="gl-text-subtle" data-testid="description">
        <gl-sprintf :message="$options.i18n.CONTAINER_CLEANUP_POLICY_DESCRIPTION">
          <template #link="{ content }">
            <gl-link :href="helpPagePath">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
      <div v-if="isLoading" class="gl-my-3">
        <gl-skeleton-loader :lines="1" />
      </div>
      <template v-else-if="isEnabled">
        <container-expiration-policy-enabled-text
          v-if="isCleanupEnabled"
          :next-run-at="containerTagsExpirationPolicy.nextRunAt"
        />
        <p v-else data-testid="empty-cleanup-policy" class="gl-mb-0 gl-text-subtle">
          {{
            s__(
              'ContainerRegistry|Registry cleanup disabled. Either no cleanup policies are enabled, or this project has no container images.',
            )
          }}
        </p>
      </template>
      <template v-else>
        <gl-alert
          v-if="showDisabledFormMessage"
          :dismissible="false"
          :title="$options.i18n.UNAVAILABLE_FEATURE_TITLE"
          variant="tip"
        >
          {{ $options.i18n.UNAVAILABLE_FEATURE_INTRO_TEXT }}

          <gl-sprintf :message="unavailableFeatureMessage">
            <template #link="{ content }">
              <gl-link :href="adminSettingsPath">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </gl-alert>
        <gl-alert v-else-if="fetchSettingsError" variant="warning" :dismissible="false">
          <gl-sprintf :message="$options.i18n.FETCH_SETTINGS_ERROR_MESSAGE" />
        </gl-alert>
      </template>
    </template>
  </gl-card>
</template>
