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
  i18n: {
    updatedAt: __('Updated %{timeAgo}'),
    createdAt: __('Created %{timeAgo}'),
    deletedUser: s__('AbuseReports|Deleted user'),
    row: s__('AbuseReports|%{reportedUser} reported for %{category} by %{reporter}'),
    rowWithCount: s__('AbuseReports|%{reportedUser} reported for %{category} by %{count} users'),
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
        ? { template: this.$options.i18n.updatedAt, timeAgo: updatedAt }
        : { template: this.$options.i18n.createdAt, timeAgo: createdAt };

      return sprintf(template, { timeAgo: getTimeago().format(timeAgo) });
    },
    title() {
      const { reportedUser, category, reporter, count } = this.report;

      const reportedUserName = reportedUser?.name || this.$options.i18n.deletedUser;
      const reporterName = reporter?.name || this.$options.i18n.deletedUser;

      const i18nRowCount = count > 1 ? this.$options.i18n.rowWithCount : this.$options.i18n.row;

      return sprintf(i18nRowCount, {
        reportedUser: reportedUserName,
        reporter: reporterName,
        category,
        count,
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
      <abuse-category :category="report.category" class="gl-mt-2 gl-mb-3" />
    </template>

    <template #right-secondary>
      <div class="gl-mt-7" data-testid="abuse-report-date">{{ displayDate }}</div>
    </template>
  </list-item>
</template>
