<script>
import ReportItem from '~/reports/components/report_item.vue';
import { STATUS_FAILED, STATUS_NEUTRAL, STATUS_SUCCESS } from '~/reports/constants';
import SmartVirtualList from '~/vue_shared/components/smart_virtual_list.vue';

const wrapIssueWithState = (status, isNew = false) => issue => ({
  status: issue.status || status,
  isNew,
  issue,
});

/**
 * Renders block of issues
 */
export default {
  components: {
    SmartVirtualList,
    ReportItem,
  },
  // Typical height of a report item in px
  typicalReportItemHeight: 32,
  /*
   The maximum amount of shown issues. This is calculated by
   ( max-height of report-block-list / typicalReportItemHeight ) + some safety margin
   We will use VirtualList if we have more items than this number.
   For entries lower than this number, the virtual scroll list calculates the total height of the element wrongly.
   */
  maxShownReportItems: 20,
  props: {
    newIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
    unresolvedIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
    resolvedIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
    neutralIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
    component: {
      type: String,
      required: false,
      default: '',
    },
    showReportSectionStatusIcon: {
      type: Boolean,
      required: false,
      default: true,
    },
    issuesUlElementClass: {
      type: String,
      required: false,
      default: '',
    },
    issueItemClass: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    issuesWithState() {
      return [
        ...this.newIssues.map(wrapIssueWithState(STATUS_FAILED, true)),
        ...this.unresolvedIssues.map(wrapIssueWithState(STATUS_FAILED)),
        ...this.neutralIssues.map(wrapIssueWithState(STATUS_NEUTRAL)),
        ...this.resolvedIssues.map(wrapIssueWithState(STATUS_SUCCESS)),
      ];
    },
    wclass() {
      return `report-block-list ${this.issuesUlElementClass}`;
    },
  },
};
</script>
<template>
  <smart-virtual-list
    :length="issuesWithState.length"
    :remain="$options.maxShownReportItems"
    :size="$options.typicalReportItemHeight"
    class="report-block-container"
    wtag="ul"
    :wclass="wclass"
  >
    <report-item
      v-for="(wrapped, index) in issuesWithState"
      :key="index"
      :issue="wrapped.issue"
      :status="wrapped.status"
      :component="component"
      :is-new="wrapped.isNew"
      :show-report-section-status-icon="showReportSectionStatusIcon"
      :class="issueItemClass"
    />
  </smart-virtual-list>
</template>
