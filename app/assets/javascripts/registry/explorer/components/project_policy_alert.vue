<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { mapState } from 'vuex';
import { approximateDuration, calculateRemainingMilliseconds } from '~/lib/utils/datetime_utility';
import {
  EXPIRATION_POLICY_ALERT_TITLE,
  EXPIRATION_POLICY_ALERT_PRIMARY_BUTTON,
  EXPIRATION_POLICY_ALERT_FULL_MESSAGE,
  EXPIRATION_POLICY_ALERT_SHORT_MESSAGE,
} from '../constants';

export default {
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
  },

  computed: {
    ...mapState(['config', 'images', 'isLoading']),
    isEmpty() {
      return !this.images || this.images.length === 0;
    },
    showAlert() {
      return this.config.expirationPolicy?.enabled;
    },
    timeTillRun() {
      const difference = calculateRemainingMilliseconds(this.config.expirationPolicy?.next_run_at);
      return approximateDuration(difference / 1000);
    },
    alertConfiguration() {
      if (this.isEmpty || this.isLoading) {
        return {
          title: null,
          primaryButton: null,
          message: EXPIRATION_POLICY_ALERT_SHORT_MESSAGE,
        };
      }
      return {
        title: EXPIRATION_POLICY_ALERT_TITLE,
        primaryButton: EXPIRATION_POLICY_ALERT_PRIMARY_BUTTON,
        message: EXPIRATION_POLICY_ALERT_FULL_MESSAGE,
      };
    },
  },
};
</script>

<template>
  <gl-alert
    v-if="showAlert"
    :dismissible="false"
    :primary-button-text="alertConfiguration.primaryButton"
    :primary-button-link="config.settingsPath"
    :title="alertConfiguration.title"
  >
    <gl-sprintf :message="alertConfiguration.message">
      <template #days>
        <strong>{{ timeTillRun }}</strong>
      </template>
      <template #link="{content}">
        <gl-link :href="config.expirationPolicyHelpPagePath" target="_blank">
          {{ content }}
        </gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
