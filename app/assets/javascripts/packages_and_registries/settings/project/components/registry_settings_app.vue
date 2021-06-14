<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { isEqual, get, isEmpty } from 'lodash';
import {
  FETCH_SETTINGS_ERROR_MESSAGE,
  UNAVAILABLE_FEATURE_TITLE,
  UNAVAILABLE_FEATURE_INTRO_TEXT,
  UNAVAILABLE_USER_FEATURE_TEXT,
  UNAVAILABLE_ADMIN_FEATURE_TEXT,
} from '~/packages_and_registries/settings/project/constants';
import expirationPolicyQuery from '~/packages_and_registries/settings/project/graphql/queries/get_expiration_policy.query.graphql';
import CleanupPolicyEnabledAlert from '~/packages_and_registries/shared/components/cleanup_policy_enabled_alert.vue';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';

import SettingsForm from './settings_form.vue';

export default {
  components: {
    SettingsBlock,
    SettingsForm,
    CleanupPolicyEnabledAlert,
    GlAlert,
    GlSprintf,
    GlLink,
  },
  inject: [
    'projectPath',
    'isAdmin',
    'adminSettingsPath',
    'enableHistoricEntries',
    'helpPagePath',
    'showCleanupPolicyOnAlert',
  ],
  i18n: {
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
  <section data-testid="registry-settings-app">
    <cleanup-policy-enabled-alert v-if="showCleanupPolicyOnAlert" :project-path="projectPath" />
    <settings-block default-expanded>
      <template #title> {{ __('Clean up image tags') }}</template>
      <template #description>
        <span data-testid="description">
          <gl-sprintf
            :message="
              __(
                'Save space and find images in the container Registry. remove unneeded tags and keep only the ones you want. %{linkStart}How does cleanup work?%{linkEnd}',
              )
            "
          >
            <template #link="{ content }">
              <gl-link :href="helpPagePath" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </span>
      </template>
      <template #default>
        <settings-form
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
                <gl-link :href="adminSettingsPath" target="_blank">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </gl-alert>
          <gl-alert v-else-if="fetchSettingsError" variant="warning" :dismissible="false">
            <gl-sprintf :message="$options.i18n.FETCH_SETTINGS_ERROR_MESSAGE" />
          </gl-alert>
        </template>
      </template>
    </settings-block>
  </section>
</template>
