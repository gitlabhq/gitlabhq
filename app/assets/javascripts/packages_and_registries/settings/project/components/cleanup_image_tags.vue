<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { isEqual, get, isEmpty } from 'lodash';
import {
  CONTAINER_CLEANUP_POLICY_TITLE,
  CONTAINER_CLEANUP_POLICY_DESCRIPTION,
  FETCH_SETTINGS_ERROR_MESSAGE,
  UNAVAILABLE_FEATURE_TITLE,
  UNAVAILABLE_FEATURE_INTRO_TEXT,
  UNAVAILABLE_USER_FEATURE_TEXT,
  UNAVAILABLE_ADMIN_FEATURE_TEXT,
} from '~/packages_and_registries/settings/project/constants';
import expirationPolicyQuery from '~/packages_and_registries/settings/project/graphql/queries/get_expiration_policy.query.graphql';
import SettingsSection from '~/vue_shared/components/settings/settings_section.vue';

import ContainerExpirationPolicyForm from './container_expiration_policy_form.vue';

export default {
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
    ContainerExpirationPolicyForm,
    SettingsSection,
  },
  inject: ['projectPath', 'isAdmin', 'adminSettingsPath', 'enableHistoricEntries', 'helpPagePath'],
  i18n: {
    CONTAINER_CLEANUP_POLICY_TITLE,
    CONTAINER_CLEANUP_POLICY_DESCRIPTION,
    UNAVAILABLE_FEATURE_TITLE,
    UNAVAILABLE_FEATURE_INTRO_TEXT,
    FETCH_SETTINGS_ERROR_MESSAGE,
  },
  apollo: {
    containerTagsExpirationPolicy: {
      query: expirationPolicyQuery,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update: (data) => data.project?.containerTagsExpirationPolicy,
      result({ data }) {
        this.workingCopy = { ...get(data, 'project.containerTagsExpirationPolicy', {}) };
      },
      error(e) {
        this.fetchSettingsError = e;
      },
    },
  },
  data() {
    return {
      fetchSettingsError: false,
      containerTagsExpirationPolicy: null,
      workingCopy: {},
    };
  },
  computed: {
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
    isEdited() {
      if (isEmpty(this.containerTagsExpirationPolicy) && isEmpty(this.workingCopy)) {
        return false;
      }
      return !isEqual(this.containerTagsExpirationPolicy, this.workingCopy);
    },
  },
};
</script>

<template>
  <settings-section
    :heading="$options.i18n.CONTAINER_CLEANUP_POLICY_TITLE"
    data-testid="container-expiration-policy-project-settings"
    class="!gl-pt-5"
  >
    <template #description>
      <gl-sprintf :message="$options.i18n.CONTAINER_CLEANUP_POLICY_DESCRIPTION">
        <template #link="{ content }">
          <gl-link :href="helpPagePath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
    <container-expiration-policy-form
      v-if="isEnabled"
      v-model="workingCopy"
      :is-loading="isLoading"
      :is-edited="isEdited"
    />
    <template v-if="!isLoading">
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
  </settings-section>
</template>
