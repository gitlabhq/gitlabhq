<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { formatNumber } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { USER_DETAILS_I18N } from '../constants';
import UserDetail from './user_detail.vue';

export default {
  name: 'UserDetails',
  components: {
    GlLink,
    GlSprintf,
    TimeAgoTooltip,
    UserDetail,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
  },
  computed: {
    verificationState() {
      return Object.entries(this.user.verificationState)
        .filter(([, v]) => v)
        .map(([k]) => this.$options.i18n.verificationMethods[k])
        .join(', ');
    },
    showCreditCardSimilarRecords() {
      return this.user.creditCard.similarRecordsCount > 1;
    },
    creditCardSimilarRecordsCount() {
      return formatNumber(this.user.creditCard.similarRecordsCount);
    },
    showPhoneNumberSimilarRecords() {
      return this.user.phoneNumber.similarRecordsCount > 1;
    },
    phoneNumberSimilarRecordsCount() {
      return formatNumber(this.user.phoneNumber.similarRecordsCount);
    },
  },
  i18n: USER_DETAILS_I18N,
};
</script>

<template>
  <div class="gl-mt-6">
    <user-detail data-testid="created-at" :label="$options.i18n.createdAt">
      <time-ago-tooltip :time="user.createdAt" />
    </user-detail>

    <user-detail data-testid="email" :label="$options.i18n.email">
      <gl-link :href="`mailto:${user.email}`">{{ user.email }}</gl-link>
    </user-detail>

    <user-detail data-testid="plan" :label="$options.i18n.plan" :value="user.plan" />

    <user-detail
      data-testid="verification"
      :label="$options.i18n.verification"
      :value="verificationState"
    />

    <user-detail
      v-if="user.creditCard"
      data-testid="credit-card-verification"
      :label="$options.i18n.creditCard"
    >
      <gl-sprintf
        v-if="showCreditCardSimilarRecords"
        :message="$options.i18n.creditCardSimilarRecords"
      >
        <template #cardMatchesLink="{ content }">
          <gl-link :href="user.creditCard.cardMatchesLink">
            <gl-sprintf :message="content">
              <template #count>{{ creditCardSimilarRecordsCount }}</template>
            </gl-sprintf>
          </gl-link>
        </template>
      </gl-sprintf>
    </user-detail>

    <user-detail
      v-if="user.phoneNumber"
      data-testid="phone-number-verification"
      :label="$options.i18n.phoneNumber"
    >
      <gl-sprintf
        v-if="showPhoneNumberSimilarRecords"
        :message="$options.i18n.phoneNumberSimilarRecords"
      >
        <template #phoneMatchesLink="{ content }">
          <gl-link :href="user.phoneNumber.phoneMatchesLink">
            <gl-sprintf :message="content">
              <template #count>{{ phoneNumberSimilarRecordsCount }}</template>
            </gl-sprintf>
          </gl-link>
        </template>
      </gl-sprintf>
    </user-detail>

    <user-detail
      v-if="user.pastClosedReports.length"
      data-testid="past-closed-reports"
      :label="$options.i18n.pastReports"
    >
      <div
        v-for="(report, index) in user.pastClosedReports"
        :key="index"
        :data-testid="`past-report-${index}`"
      >
        <gl-sprintf :message="$options.i18n.reportedFor">
          <template #reportLink="{ content }">
            <gl-link :href="report.reportPath">{{ content }}</gl-link>
          </template>
          <template #category>{{ report.category }}</template>
          <template #timeAgo>
            <time-ago-tooltip :time="report.createdAt" />
          </template>
        </gl-sprintf>
      </div>
    </user-detail>

    <user-detail
      data-testid="normal-location"
      :label="$options.i18n.normalLocation"
      :value="user.mostUsedIp || user.lastSignInIp"
    />

    <user-detail
      data-testid="last-sign-in-ip"
      :label="$options.i18n.lastSignInIp"
      :value="user.lastSignInIp"
    />

    <user-detail
      data-testid="user-snippets-count"
      :label="$options.i18n.snippets"
      :value="$options.i18n.snippetsCount(user.snippetsCount)"
    />

    <user-detail
      data-testid="user-groups-count"
      :label="$options.i18n.groups"
      :value="$options.i18n.groupsCount(user.groupsCount)"
    />

    <user-detail
      data-testid="user-notes-count"
      :label="$options.i18n.notes"
      :value="$options.i18n.notesCount(user.notesCount)"
    />
  </div>
</template>
