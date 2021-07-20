<script>
import { GlIcon, GlLink, GlModal, GlModalDirective, GlLoadingIcon } from '@gitlab/ui';
import { IssuableType } from '~/issue_show/constants';
import { s__, __ } from '~/locale';
import { timeTrackingQueries } from '~/sidebar/constants';

import eventHub from '../../event_hub';
import TimeTrackingCollapsedState from './collapsed_state.vue';
import TimeTrackingComparisonPane from './comparison_pane.vue';
import TimeTrackingHelpState from './help_state.vue';
import TimeTrackingReport from './report.vue';
import TimeTrackingSpentOnlyPane from './spent_only_pane.vue';

export default {
  name: 'IssuableTimeTracker',
  i18n: {
    noTimeTrackingText: __('No estimate or time spent'),
    estimatedOnlyText: s__('TimeTracking|Estimated:'),
  },
  components: {
    GlIcon,
    GlLink,
    GlModal,
    GlLoadingIcon,
    TimeTrackingCollapsedState,
    TimeTrackingSpentOnlyPane,
    TimeTrackingComparisonPane,
    TimeTrackingHelpState,
    TimeTrackingReport,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: {
    issuableType: {
      default: null,
    },
  },
  props: {
    limitToHours: {
      type: Boolean,
      default: false,
      required: false,
    },
    fullPath: {
      type: String,
      required: false,
      default: '',
    },
    issuableId: {
      type: String,
      required: false,
      default: '',
    },
    issuableIid: {
      type: String,
      required: false,
      default: '',
    },
    initialTimeTracking: {
      type: Object,
      required: false,
      default: null,
    },
    /*
      In issue list, "time-tracking-collapsed-state" is always rendered even if the sidebar isn't collapsed.
      The actual hiding is controlled with css classes:
        Hide "time-tracking-collapsed-state"
          if .right-sidebar .right-sidebar-collapsed .sidebar-collapsed-icon
        Show "time-tracking-collapsed-state"
          if .right-sidebar .right-sidebar-expanded .sidebar-collapsed-icon

      In Swimlanes sidebar, we do not use collapsed state at all.
    */
    showCollapsed: {
      type: Boolean,
      default: true,
      required: false,
    },
  },
  data() {
    return {
      showHelp: false,
      timeTracking: {
        ...this.initialTimeTracking,
      },
    };
  },
  apollo: {
    issuableTimeTracking: {
      query() {
        return timeTrackingQueries[this.issuableType].query;
      },
      skip() {
        // Skip the query if either of the conditions are true
        // 1. issuableType is not provided
        // 2. Time tracking info was provided via prop
        // 3. issuableIid and fullPath are not provided
        if (!this.issuableType || !timeTrackingQueries[this.issuableType]) {
          return true;
        } else if (this.initialTimeTracking) {
          return true;
        } else if (!this.issuableIid || !this.fullPath) {
          return true;
        }
        return false;
      },
      variables() {
        return {
          iid: this.issuableIid,
          fullPath: this.fullPath,
        };
      },
      update(data) {
        this.timeTracking = {
          ...data.workspace?.issuable,
        };
      },
    },
  },
  computed: {
    isTimeTrackingInfoLoading() {
      return this.$apollo?.queries.issuableTimeTracking?.loading ?? false;
    },
    timeEstimate() {
      return this.timeTracking?.timeEstimate || 0;
    },
    totalTimeSpent() {
      return this.timeTracking?.totalTimeSpent || 0;
    },
    humanTimeEstimate() {
      return this.timeTracking?.humanTimeEstimate || '';
    },
    humanTotalTimeSpent() {
      return this.timeTracking?.humanTotalTimeSpent || '';
    },
    hasTotalTimeSpent() {
      return Boolean(this.totalTimeSpent);
    },
    hasTimeEstimate() {
      return Boolean(this.timeEstimate);
    },
    showComparisonState() {
      return this.hasTimeEstimate && this.hasTotalTimeSpent;
    },
    showEstimateOnlyState() {
      return this.hasTimeEstimate && !this.hasTotalTimeSpent;
    },
    showSpentOnlyState() {
      return this.hasTotalTimeSpent && !this.hasTimeEstimate;
    },
    showNoTimeTrackingState() {
      return !this.hasTimeEstimate && !this.hasTotalTimeSpent;
    },
    showHelpState() {
      return Boolean(this.showHelp);
    },
    isTimeReportSupported() {
      return (
        [IssuableType.Issue, IssuableType.MergeRequest].includes(this.issuableType) &&
        this.issuableId
      );
    },
  },
  watch: {
    /**
     * When `initialTimeTracking` is provided via prop,
     * we don't query the same via GraphQl and instead
     * monitor it for any updates (eg; Epic Swimlanes)
     */
    initialTimeTracking(timeTracking) {
      this.timeTracking = timeTracking;
    },
  },
  created() {
    eventHub.$on('timeTracker:refresh', this.refresh);
  },
  methods: {
    toggleHelpState(show) {
      this.showHelp = show;
    },
    refresh() {
      this.$apollo.queries.issuableTimeTracking.refetch();
    },
  },
};
</script>

<template>
  <div v-cloak class="time-tracker time-tracking-component-wrap" data-testid="time-tracker">
    <time-tracking-collapsed-state
      v-if="showCollapsed"
      :show-comparison-state="showComparisonState"
      :show-no-time-tracking-state="showNoTimeTrackingState"
      :show-help-state="showHelpState"
      :show-spent-only-state="showSpentOnlyState"
      :show-estimate-only-state="showEstimateOnlyState"
      :time-spent-human-readable="humanTotalTimeSpent"
      :time-estimate-human-readable="humanTimeEstimate"
    />
    <div class="hide-collapsed gl-line-height-20 gl-text-gray-900">
      {{ __('Time tracking') }}
      <gl-loading-icon v-if="isTimeTrackingInfoLoading" size="sm" inline />
      <div
        v-if="!showHelpState"
        data-testid="helpButton"
        class="help-button float-right"
        @click="toggleHelpState(true)"
      >
        <gl-icon name="question-o" />
      </div>
      <div
        v-else
        data-testid="closeHelpButton"
        class="close-help-button float-right"
        @click="toggleHelpState(false)"
      >
        <gl-icon name="close" />
      </div>
    </div>
    <div v-if="!isTimeTrackingInfoLoading" class="hide-collapsed">
      <div v-if="showEstimateOnlyState" data-testid="estimateOnlyPane">
        <span class="gl-font-weight-bold">{{ $options.i18n.estimatedOnlyText }} </span
        >{{ humanTimeEstimate }}
      </div>
      <time-tracking-spent-only-pane
        v-if="showSpentOnlyState"
        :time-spent-human-readable="humanTotalTimeSpent"
      />
      <div v-if="showNoTimeTrackingState" data-testid="noTrackingPane">
        <span class="gl-text-gray-500">{{ $options.i18n.noTimeTrackingText }}</span>
      </div>
      <time-tracking-comparison-pane
        v-if="showComparisonState"
        :time-estimate="timeEstimate"
        :time-spent="totalTimeSpent"
        :time-spent-human-readable="humanTotalTimeSpent"
        :time-estimate-human-readable="humanTimeEstimate"
        :limit-to-hours="limitToHours"
      />
      <template v-if="isTimeReportSupported">
        <gl-link
          v-if="hasTotalTimeSpent"
          v-gl-modal="'time-tracking-report'"
          data-testid="reportLink"
          href="#"
        >
          {{ __('Time tracking report') }}
        </gl-link>
        <gl-modal
          modal-id="time-tracking-report"
          :title="__('Time tracking report')"
          :hide-footer="true"
        >
          <time-tracking-report :limit-to-hours="limitToHours" :issuable-id="issuableId" />
        </gl-modal>
      </template>
      <transition name="help-state-toggle">
        <time-tracking-help-state v-if="showHelpState" />
      </transition>
    </div>
  </div>
</template>
