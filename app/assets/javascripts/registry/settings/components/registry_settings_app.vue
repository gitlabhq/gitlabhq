<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';

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
  i18n: {
    UNAVAILABLE_FEATURE_TITLE,
    UNAVAILABLE_FEATURE_INTRO_TEXT,
    FETCH_SETTINGS_ERROR_MESSAGE,
  },
  data() {
    return {
      fetchSettingsError: false,
    };
  },
  computed: {
    ...mapState(['isAdmin', 'adminSettingsPath']),
    ...mapGetters({ isDisabled: 'getIsDisabled' }),
    showSettingForm() {
      return !this.isDisabled && !this.fetchSettingsError;
    },
    showDisabledFormMessage() {
      return this.isDisabled && !this.fetchSettingsError;
    },
    unavailableFeatureMessage() {
      return this.isAdmin ? UNAVAILABLE_ADMIN_FEATURE_TEXT : UNAVAILABLE_USER_FEATURE_TEXT;
    },
  },
  mounted() {
    this.fetchSettings().catch(() => {
      this.fetchSettingsError = true;
    });
  },
  methods: {
    ...mapActions(['fetchSettings']),
  },
};
</script>

<template>
  <div>
    <settings-form v-if="showSettingForm" />
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
