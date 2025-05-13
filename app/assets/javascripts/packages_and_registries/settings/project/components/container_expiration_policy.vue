<script>
import { GlAlert, GlSprintf, GlLink, GlButton } from '@gitlab/ui';
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
import CrudComponent from '~/vue_shared/components/crud_component.vue';

export default {
  components: {
    ContainerExpirationPolicyEnabledText,
    GlAlert,
    GlSprintf,
    GlLink,
    GlButton,
    CrudComponent,
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
  <crud-component
    :title="$options.i18n.CONTAINER_CLEANUP_POLICY_TITLE"
    :is-loading="isLoading"
    data-testid="container-expiration-policy-project-settings"
  >
    <template #actions>
      <gl-button
        v-if="isEnabled"
        data-testid="rules-button"
        :href="cleanupSettingsPath"
        :loading="isLoading"
        category="secondary"
        size="small"
        class="gl-self-start"
      >
        {{ cleanupRulesButtonText }}
      </gl-button>
    </template>
    <template #description>
      <gl-sprintf :message="$options.i18n.CONTAINER_CLEANUP_POLICY_DESCRIPTION">
        <template #link="{ content }">
          <gl-link :href="helpPagePath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>

    <template v-if="isEnabled">
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
  </crud-component>
</template>
