<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { n__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

import {
  WARNING_ALERT_TITLE,
  DANGER_ALERT_TITLE,
  REACHED_LIMIT_UPGRADE_SUGGESTION_MESSAGE,
  REACHED_LIMIT_VARIANT,
  CLOSE_TO_LIMIT_MESSAGE,
  CLOSE_TO_LIMIT_VARIANT,
} from '../constants';

export default {
  name: 'UserLimitNotification',
  components: { GlAlert, GlSprintf, GlLink },
  inject: ['name'],
  props: {
    limitVariant: {
      type: String,
      required: true,
    },
    usersLimitDataset: {
      type: Object,
      required: true,
    },
  },
  computed: {
    limitAttributes() {
      return {
        [CLOSE_TO_LIMIT_VARIANT]: {
          variant: 'warning',
          title: this.title(WARNING_ALERT_TITLE, this.usersLimitDataset.remainingSeats),
          message: CLOSE_TO_LIMIT_MESSAGE,
        },
        [REACHED_LIMIT_VARIANT]: {
          variant: 'danger',
          title: this.title(DANGER_ALERT_TITLE, this.usersLimitDataset.freeUsersLimit),
          message: REACHED_LIMIT_UPGRADE_SUGGESTION_MESSAGE,
        },
      };
    },
  },
  methods: {
    title(titleTemplate, count) {
      return sprintf(titleTemplate, {
        count,
        members: n__('member', 'members', count),
        name: this.name,
      });
    },

    message(messageTemplate, dashboardLimit) {
      return sprintf(messageTemplate, {
        dashboardLimit,
      });
    },
  },
  freeUserLimitHelpPath: helpPagePath('user/free_user_limit'),
};
</script>

<template>
  <gl-alert
    :variant="limitAttributes[limitVariant].variant"
    :dismissible="false"
    :title="limitAttributes[limitVariant].title"
  >
    <gl-sprintf :message="limitAttributes[limitVariant].message">
      <template #freeUserLimitLink="{ content }">
        <gl-link :href="$options.freeUserLimitHelpPath" class="gl-label-link">{{
          content
        }}</gl-link>
      </template>
      <template #trialLink="{ content }">
        <gl-link
          :href="usersLimitDataset.newTrialRegistrationPath"
          class="gl-label-link"
          data-track-action="click_link"
          :data-track-label="`start_trial_user_limit_notification_${limitVariant}`"
          data-testid="trial-link"
        >
          {{ content }}
        </gl-link>
      </template>
      <template #upgradeLink="{ content }">
        <gl-link
          :href="usersLimitDataset.purchasePath"
          class="gl-label-link"
          data-track-action="click_link"
          :data-track-label="`upgrade_user_limit_notification_${limitVariant}`"
          data-testid="upgrade-link"
        >
          {{ content }}
        </gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
