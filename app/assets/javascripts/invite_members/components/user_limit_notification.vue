<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { n__, sprintf } from '~/locale';

import {
  WARNING_ALERT_TITLE,
  DANGER_ALERT_TITLE,
  REACHED_LIMIT_MESSAGE,
  CLOSE_TO_LIMIT_MESSAGE,
} from '../constants';

const CLOSE_TO_LIMIT_COUNT = 2;

export default {
  name: 'UserLimitNotification',
  components: { GlAlert, GlSprintf, GlLink },
  inject: ['name'],
  props: {
    reachedLimit: {
      type: Boolean,
      required: true,
    },
    usersLimitDataset: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    freeUsersLimit() {
      return this.usersLimitDataset.freeUsersLimit;
    },
    membersCount() {
      return this.usersLimitDataset.membersCount;
    },
    newTrialRegistrationPath() {
      return this.usersLimitDataset.newTrialRegistrationPath;
    },
    purchasePath() {
      return this.usersLimitDataset.purchasePath;
    },
    closeToLimit() {
      if (this.freeUsersLimit && this.membersCount) {
        return this.membersCount >= this.freeUsersLimit - CLOSE_TO_LIMIT_COUNT;
      }

      return false;
    },
    warningAlertTitle() {
      return sprintf(WARNING_ALERT_TITLE, {
        count: this.freeUsersLimit - this.membersCount,
        members: this.pluralMembers(this.freeUsersLimit - this.membersCount),
        name: this.name,
      });
    },
    dangerAlertTitle() {
      return sprintf(DANGER_ALERT_TITLE, {
        count: this.freeUsersLimit,
        members: this.pluralMembers(this.freeUsersLimit),
        name: this.name,
      });
    },
    variant() {
      return this.reachedLimit ? 'danger' : 'warning';
    },
    title() {
      return this.reachedLimit ? this.dangerAlertTitle : this.warningAlertTitle;
    },
    message() {
      if (this.reachedLimit) {
        return this.$options.i18n.reachedLimitMessage;
      }

      return this.$options.i18n.closeToLimitMessage;
    },
  },
  methods: {
    pluralMembers(count) {
      return n__('member', 'members', count);
    },
  },
  i18n: {
    reachedLimitMessage: REACHED_LIMIT_MESSAGE,
    closeToLimitMessage: CLOSE_TO_LIMIT_MESSAGE,
  },
};
</script>

<template>
  <gl-alert
    v-if="reachedLimit || closeToLimit"
    :variant="variant"
    :dismissible="false"
    :title="title"
  >
    <gl-sprintf :message="message">
      <template #trialLink="{ content }">
        <gl-link :href="newTrialRegistrationPath" class="gl-label-link">{{ content }}</gl-link>
      </template>
      <template #upgradeLink="{ content }">
        <gl-link :href="purchasePath" class="gl-label-link">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
