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
    showSimilarRecords() {
      return this.user.creditCard.similarRecordsCount > 1;
    },
    similarRecordsCount() {
      return formatNumber(this.user.creditCard.similarRecordsCount);
    },
  },
  i18n: USER_DETAILS_I18N,
};
</script>

<template>
  <div class="gl-mt-6">
    <user-detail data-testid="createdAt" :label="$options.i18n.createdAt">
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
    <user-detail v-if="user.creditCard" data-testid="creditCard" :label="$options.i18n.creditCard">
      <gl-sprintf :message="$options.i18n.registeredWith">
        <template #name>{{ user.creditCard.name }}</template>
      </gl-sprintf>
      <gl-sprintf v-if="showSimilarRecords" :message="$options.i18n.similarRecords">
        <template #cardMatchesLink="{ content }">
          <gl-link :href="user.creditCard.cardMatchesLink">
            <gl-sprintf :message="content">
              <template #count>{{ similarRecordsCount }}</template>
            </gl-sprintf>
          </gl-link>
        </template>
      </gl-sprintf>
    </user-detail>
    <user-detail
      v-if="user.otherReports.length"
      data-testid="otherReports"
      :label="$options.i18n.otherReports"
    >
      <div
        v-for="(report, index) in user.otherReports"
        :key="index"
        :data-testid="`other-report-${index}`"
      >
        <gl-sprintf :message="$options.i18n.otherReport">
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
      data-testid="normalLocation"
      :label="$options.i18n.normalLocation"
      :value="user.mostUsedIp || user.lastSignInIp"
    />
    <user-detail
      data-testid="lastSignInIp"
      :label="$options.i18n.lastSignInIp"
      :value="user.lastSignInIp"
    />
    <user-detail
      data-testid="snippets"
      :label="$options.i18n.snippets"
      :value="$options.i18n.snippetsCount(user.snippetsCount)"
    />
    <user-detail
      data-testid="groups"
      :label="$options.i18n.groups"
      :value="$options.i18n.groupsCount(user.groupsCount)"
    />
    <user-detail
      data-testid="notes"
      :label="$options.i18n.notes"
      :value="$options.i18n.notesCount(user.notesCount)"
    />
  </div>
</template>
