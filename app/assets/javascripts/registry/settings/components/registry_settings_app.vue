<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { isEqual, get } from 'lodash';
import expirationPolicyQuery from '../graphql/queries/get_expiration_policy.graphql';
import { FETCH_SETTINGS_ERROR_MESSAGE } from '../../shared/constants';

import SettingsForm from './settings_form.vue';
import {
  UNAVAILABLE_FEATURE_TITLE,
  UNAVAILABLE_FEATURE_INTRO_TEXT,
  UNAVAILABLE_USER_FEATURE_TEXT,
  UNAVAILABLE_ADMIN_FEATURE_TEXT,
} from '../constants';

export default {
  components: {
    SettingsForm,
    GlAlert,
    GlSprintf,
    GlLink,
  },
  inject: ['projectPath', 'isAdmin', 'adminSettingsPath', 'enableHistoricEntries'],
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
      update: data => data.project?.containerExpirationPolicy,
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
  <div>
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
  </div>
</template>
