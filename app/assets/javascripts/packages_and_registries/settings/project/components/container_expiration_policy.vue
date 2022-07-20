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
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';

import ContainerExpirationPolicyForm from './container_expiration_policy_form.vue';

export default {
  components: {
    SettingsBlock,
    GlAlert,
    GlSprintf,
    GlLink,
    ContainerExpirationPolicyForm,
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
    containerExpirationPolicy: {
      query: expirationPolicyQuery,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update: (data) => data.project?.containerExpirationPolicy,
      result({ data }) {
        this.workingCopy = { ...get(data, 'project.containerExpirationPolicy', {}) };
      },
      error(e) {
        this.fetchSettingsError = e;
      },
    },
  },
  data() {
    return {
      fetchSettingsError: false,
      containerExpirationPolicy: null,
      workingCopy: {},
    };
  },
  computed: {
    isDisabled() {
      return !(this.containerExpirationPolicy || this.enableHistoricEntries);
    },
    showDisabledFormMessage() {
      return this.isDisabled && !this.fetchSettingsError;
    },
    unavailableFeatureMessage() {
      return this.isAdmin ? UNAVAILABLE_ADMIN_FEATURE_TEXT : UNAVAILABLE_USER_FEATURE_TEXT;
    },
    isEdited() {
      if (isEmpty(this.containerExpirationPolicy) && isEmpty(this.workingCopy)) {
        return false;
      }
      return !isEqual(this.containerExpirationPolicy, this.workingCopy);
    },
  },
  methods: {
    restoreOriginal() {
      this.workingCopy = { ...this.containerExpirationPolicy };
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
      <container-expiration-policy-form
        v-if="!isDisabled"
        v-model="workingCopy"
        :is-loading="$apollo.queries.containerExpirationPolicy.loading"
        :is-edited="isEdited"
        @reset="restoreOriginal"
      />
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
  </settings-block>
</template>
