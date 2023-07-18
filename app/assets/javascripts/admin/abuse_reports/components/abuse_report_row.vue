<script>
import { GlLink } from '@gitlab/ui';
import { getTimeago } from '~/lib/utils/datetime_utility';
import { queryToObject } from '~/lib/utils/url_utility';
import { s__, __, sprintf } from '~/locale';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import { SORT_UPDATED_AT } from '../constants';
import AbuseCategory from './abuse_category.vue';

export default {
  name: 'AbuseReportRow',
  components: {
    GlLink,
    ListItem,
    AbuseCategory,
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
    title() {
      const { reportedUser, category, reporter } = this.report;
      const template = s__('AbuseReports|%{reportedUser} reported for %{category} by %{reporter}');
      return sprintf(template, {
        reportedUser: reportedUser?.name || s__('AbuseReports|Deleted user'),
        reporter: reporter?.name || s__('AbuseReports|Deleted user'),
        category,
      });
    },
  },
};
</script>

<template>
  <list-item data-testid="abuse-report-row">
    <template #left-primary>
      <gl-link
        :href="report.reportPath"
        class="gl-font-weight-normal gl-pt-4 gl-text-gray-900"
        data-testid="abuse-report-title"
      >
        {{ title }}
      </gl-link>
    </template>
    <template #left-secondary>
      <abuse-category
        :category="report.category"
        class="gl-mt-2 gl-mb-3"
        data-testid="abuse-report-category"
      />
    </template>

    <template #right-secondary>
      <div class="gl-mt-7" data-testid="abuse-report-date">{{ displayDate }}</div>
    </template>
  </list-item>
</template>
