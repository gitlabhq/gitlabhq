<script>
import { GlSprintf } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import HistoryItem from '~/vue_shared/components/registry/history_item.vue';
import { HISTORY_ITEMS_I18N } from '../constants';

export default {
  name: 'ActivityHistoryItem',
  components: {
    GlSprintf,
    TimeAgoTooltip,
    HistoryItem,
  },
  props: {
    report: {
      type: Object,
      required: true,
    },
  },
  computed: {
    reporter() {
      return this.report.reporter;
    },
    reporterName() {
      return this.reporter?.name || this.$options.i18n.deletedReporter;
    },
  },
  i18n: HISTORY_ITEMS_I18N,
};
</script>

<template>
  <history-item icon="warning">
    <div class="gl-flex gl-flex-col sm:gl-flex-row">
      <gl-sprintf :message="$options.i18n.reportedByForCategory">
        <template #name>{{ reporterName }}</template>
        <template #category>{{ report.category }}</template>
      </gl-sprintf>
      <time-ago-tooltip :time="report.reportedAt" class="gl-text-subtle sm:gl-ml-3" />
    </div>
  </history-item>
</template>
