<script>
import { GlAlert, GlSprintf, GlLink, GlCard, GlButton } from '@gitlab/ui';
import {
  CONTAINER_CLEANUP_POLICY_TITLE,
  CONTAINER_CLEANUP_POLICY_DESCRIPTION,
  CONTAINER_CLEANUP_POLICY_EDIT_RULES,
  CONTAINER_CLEANUP_POLICY_RULES_DESCRIPTION,
  CONTAINER_CLEANUP_POLICY_SET_RULES,
  FETCH_SETTINGS_ERROR_MESSAGE,
  UNAVAILABLE_FEATURE_TITLE,
  UNAVAILABLE_FEATURE_INTRO_TEXT,
  UNAVAILABLE_USER_FEATURE_TEXT,
  UNAVAILABLE_ADMIN_FEATURE_TEXT,
} from '~/packages_and_registries/settings/project/constants';
import expirationPolicyQuery from '~/packages_and_registries/settings/project/graphql/queries/get_expiration_policy.query.graphql';
import SettingsBlock from '~/packages_and_registries/shared/components/settings_block.vue';

export default {
  components: {
    SettingsBlock,
    GlAlert,
    GlSprintf,
    GlLink,
    GlCard,
    GlButton,
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
    CONTAINER_CLEANUP_POLICY_RULES_DESCRIPTION,
    CONTAINER_CLEANUP_POLICY_SET_RULES,
    UNAVAILABLE_FEATURE_TITLE,
    UNAVAILABLE_FEATURE_INTRO_TEXT,
    FETCH_SETTINGS_ERROR_MESSAGE,
  },
  apollo: {
    containerExpirationPolicy: {
      query: expirationPolicyQuery,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update: (data) => data.project?.containerExpirationPolicy,
      error(e) {
        this.fetchSettingsError = e;
      },
    },
  },
  data() {
    return {
      fetchSettingsError: false,
      containerExpirationPolicy: null,
    };
  },
  computed: {
    isCleanupEnabled() {
      return this.containerExpirationPolicy?.enabled ?? false;
    },
    isEnabled() {
      return this.containerExpirationPolicy || this.enableHistoricEntries;
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
  <settings-block data-testid="container-expiration-policy-project-settings">
    <template #title> {{ $options.i18n.CONTAINER_CLEANUP_POLICY_TITLE }}</template>
    <template #description>
      <span>
        <gl-sprintf :message="$options.i18n.CONTAINER_CLEANUP_POLICY_DESCRIPTION">
          <template #link="{ content }">
            <gl-link :href="helpPagePath">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </span>
    </template>
    <template #default>
      <gl-card v-if="isEnabled">
        <p data-testid="description">
          {{ $options.i18n.CONTAINER_CLEANUP_POLICY_RULES_DESCRIPTION }}
        </p>
        <gl-button
          data-testid="rules-button"
          :href="cleanupSettingsPath"
          category="secondary"
          variant="confirm"
        >
          {{ cleanupRulesButtonText }}
        </gl-button>
      </gl-card>
      <template v-if="!$apollo.queries.containerExpirationPolicy.loading">
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
  </settings-block>
</template>
