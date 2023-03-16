<script>
import { getTimeago } from '~/lib/utils/datetime_utility';
import { __, sprintf } from '~/locale';
import ListItem from '~/vue_shared/components/registry/list_item.vue';

export default {
  name: 'AbuseReportRow',
  components: {
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
    title() {
      const { reportedUser, reporter, category } = this.report;
      const template = __('%{reported} reported for %{category} by %{reporter}');
      return sprintf(template, { reported: reportedUser.name, reporter: reporter.name, category });
    },
  },
};
</script>

<template>
  <list-item data-testid="abuse-report-row">
    <template #left-primary>
      <div class="gl-font-weight-normal" data-testid="title">{{ title }}</div>
    </template>

    <template #right-secondary>
      <div data-testid="updated-at">{{ updatedAt }}</div>
    </template>
  </list-item>
</template>
