<script>
import { s__, n__, sprintf } from '~/locale';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import MrWidget from './widget.vue';

const FAILED_STATUSES = [EXTENSION_ICONS.failed, EXTENSION_ICONS.error];

const STATUS_PRECEDENCE = [
  ...FAILED_STATUSES,
  EXTENSION_ICONS.warning,
  EXTENSION_ICONS.success,
  EXTENSION_ICONS.neutral,
];

export default {
  name: 'WidgetMergeReports',
  components: {
    MrWidget,
  },
  mixins: [glSlotsMixin],
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      reports: {},
      isExpanded: false,
    };
  },
  computed: {
    reportCount() {
      return Object.keys(this.reports).length;
    },
    loadingState() {
      return this.reportCount === 0 ? MrWidget.LOADING_STATE_COLLAPSED : undefined;
    },
    totalCount() {
      return Object.values(this.reports).reduce((total, { count }) => total + count, 0);
    },
    reportsWithChanges() {
      return Object.values(this.reports).filter(({ count }) => count > 0).length;
    },
    failedReports() {
      return Object.entries(this.reports)
        .filter(([, { status }]) => FAILED_STATUSES.includes(status))
        .map(([key]) => key);
    },
    statusIcon() {
      const statuses = Object.values(this.reports).map(({ status }) => status);

      return (
        STATUS_PRECEDENCE.find((status) => statuses.includes(status)) || EXTENSION_ICONS.neutral
      );
    },
    summary() {
      if (this.totalCount === 0) {
        return {
          title: sprintf(
            s__('MrReports|%{strong_start}Merge reports (%{reportCount})%{strong_end}'),
            { reportCount: this.reportCount },
          ),
        };
      }

      const changes = sprintf(
        n__('MrReports|%{count} new change', 'MrReports|%{count} new changes', this.totalCount),
        { count: this.totalCount },
      );
      const reports = sprintf(
        n__('MrReports|%{count} report', 'MrReports|%{count} reports', this.reportsWithChanges),
        { count: this.reportsWithChanges },
      );

      return {
        title: sprintf(
          s__(
            'MrReports|%{strong_start}Merge reports (%{reportCount}):%{strong_end} %{changes} across %{reports}',
          ),
          { reportCount: this.reportCount, changes, reports },
        ),
      };
    },
    actionButtons() {
      return [
        {
          text: s__('MrReports|View reports'),
          href: this.mr.reportsTabPath,
          onClick: (action, e) => {
            e.preventDefault();
            window.history.pushState(null, null, action.href);
            window.dispatchEvent(new PopStateEvent('popstate'));
          },
        },
      ];
    },
  },
  methods: {
    onReportLoaded(key, count, status) {
      this.reports = { ...this.reports, [key]: { count, status } };
    },
    isReportVisible(key) {
      return this.isExpanded || this.failedReports.includes(key);
    },
    onToggle({ expanded }) {
      this.isExpanded = expanded;
    },
  },
};
</script>

<template>
  <mr-widget
    :action-buttons="actionButtons"
    :loading-text="s__('MrReports|Loading merge reports')"
    :loading-state="loadingState"
    :summary="summary"
    :status-icon-name="statusIcon"
    :widget-name="$options.name"
    :expand-button-label="s__('MrReports|Expand merge reports')"
    :collapse-button-label="s__('MrReports|Collapse merge reports')"
    :show-content-when-collapsed="failedReports.length > 0"
    :telemetry="false"
    is-collapsible
    persist-content
    data-testid="merge-reports-widget"
    @toggle="onToggle"
  >
    <template v-if="glSlots().reports" #content>
      <slot
        name="reports"
        :on-report-loaded="onReportLoaded"
        :is-report-visible="isReportVisible"
      ></slot>
    </template>
  </mr-widget>
</template>
