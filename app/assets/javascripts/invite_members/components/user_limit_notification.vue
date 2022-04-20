<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { s__, n__, sprintf } from '~/locale';

const CLOSE_TO_LIMIT_COUNT = 2;

const WARNING_ALERT_TITLE = s__(
  'InviteMembersModal|You only have space for %{count} more %{members} in %{name}',
);

const DANGER_ALERT_TITLE = s__(
  "InviteMembersModal|You've reached your %{count} %{members} limit for %{name}",
);

const CLOSE_TO_LIMIT_MESSAGE = s__(
  'InviteMembersModal|To get more members an owner of this namespace can %{trialLinkStart}start a trial%{trialLinkEnd} or %{upgradeLinkStart}upgrade%{upgradeLinkEnd} to a paid tier.',
);

const REACHED_LIMIT_MESSAGE = s__(
  'InviteMembersModal|New members will be unable to participate. You can manage your members by removing ones you no longer need.',
).concat(' ', CLOSE_TO_LIMIT_MESSAGE);

export default {
  name: 'UserLimitNotification',
  components: { GlAlert, GlSprintf, GlLink },
  inject: ['name', 'newTrialRegistrationPath', 'purchasePath', 'freeUsersLimit', 'membersCount'],
  computed: {
    reachedLimit() {
      return this.isLimit();
    },
    closeToLimit() {
      return this.isLimit(CLOSE_TO_LIMIT_COUNT);
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
    isLimit(deviation = 0) {
      if (this.freeUsersLimit && this.membersCount) {
        return this.membersCount >= this.freeUsersLimit - deviation;
      }

      return false;
    },
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
