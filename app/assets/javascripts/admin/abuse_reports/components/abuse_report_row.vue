<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { getTimeago } from '~/lib/utils/datetime_utility';
import { __, sprintf } from '~/locale';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import AbuseReportActions from './abuse_report_actions.vue';

export default {
  name: 'AbuseReportRow',
  components: {
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
    updatedAt() {
      const template = __('Updated %{timeAgo}');
      return sprintf(template, { timeAgo: getTimeago().format(this.report.updatedAt) });
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
      <div class="gl-font-weight-normal" data-testid="title">
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

    <template #right-secondary>
      <div data-testid="updated-at">{{ updatedAt }}</div>

      <abuse-report-actions :report="report" />
    </template>
  </list-item>
</template>
