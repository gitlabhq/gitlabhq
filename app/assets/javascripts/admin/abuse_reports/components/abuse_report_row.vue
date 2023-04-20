<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { getTimeago } from '~/lib/utils/datetime_utility';
import { queryToObject } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import { SORT_UPDATED_AT } from '../constants';
import AbuseReportActions from './abuse_report_actions.vue';
import AbuseReportDetails from './abuse_report_details.vue';

export default {
  name: 'AbuseReportRow',
  components: {
    AbuseReportDetails,
    GlLink,
    GlSprintf,
    AbuseReportActions,
    ListItem,
  },
  props: {
    report: {
      type: Object,
      required: true,
    },
  },
  computed: {
    displayDate() {
      const { sort } = queryToObject(window.location.search);
      const { createdAt, updatedAt } = this.report;
      const { template, timeAgo } = Object.values(SORT_UPDATED_AT.sortDirection).includes(sort)
        ? { template: __('Updated %{timeAgo}'), timeAgo: updatedAt }
        : { template: __('Created %{timeAgo}'), timeAgo: createdAt };

      return sprintf(template, { timeAgo: getTimeago().format(timeAgo) });
    },
    reported() {
      const { reportedUser } = this.report;
      return sprintf('%{userLinkStart}%{reported}%{userLinkEnd}', {
        reported: reportedUser.name,
      });
    },
    reporter() {
      const { reporter } = this.report;
      return sprintf('%{reporterLinkStart}%{reporter}%{reporterLinkEnd}', {
        reporter: reporter.name,
      });
    },
    title() {
      const { category } = this.report;
      const template = __('%{reported} reported for %{category} by %{reporter}');
      return sprintf(template, { reported: this.reported, reporter: this.reporter, category });
    },
  },
};
</script>

<template>
  <list-item data-testid="abuse-report-row">
    <template #left-primary>
      <div class="gl-font-weight-normal gl-mb-2" data-testid="title">
        <gl-sprintf :message="title">
          <template #userLink="{ content }">
            <gl-link :href="report.reportedUserPath">{{ content }}</gl-link>
          </template>
          <template #reporterLink="{ content }">
            <gl-link :href="report.reporterPath">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </div>
    </template>

    <template #left-secondary>
      <abuse-report-details :report="report" />
    </template>

    <template #right-secondary>
      <div data-testid="abuse-report-date">{{ displayDate }}</div>
      <abuse-report-actions :report="report" />
    </template>
  </list-item>
</template>
