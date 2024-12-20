<script>
import {
  GlLink,
  GlModal,
  GlButton,
  GlModalDirective,
  GlLoadingIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import { s__, __ } from '~/locale';

import { timeTrackingQueries } from '../../queries/constants';
import eventHub from '../../event_hub';
import TimeTrackingCollapsedState from './collapsed_state.vue';
import TimeTrackingComparisonPane from './comparison_pane.vue';
import TimeTrackingSpentOnlyPane from './spent_only_pane.vue';
import TimeTrackingReport from './time_tracking_report.vue';
import { CREATE_TIMELOG_MODAL_ID, SET_TIME_ESTIMATE_MODAL_ID } from './constants';
import CreateTimelogForm from './create_timelog_form.vue';
import SetTimeEstimateForm from './set_time_estimate_form.vue';

export default {
  name: 'IssuableTimeTracker',
  i18n: {
    noTimeTrackingText: __('No estimate or time spent'),
    estimatedOnlyText: s__('TimeTracking|Estimated:'),
  },
  components: {
    GlLink,
    GlModal,
    GlButton,
    GlLoadingIcon,
    TimeTrackingCollapsedState,
    TimeTrackingSpentOnlyPane,
    TimeTrackingComparisonPane,
    TimeTrackingReport,
    CreateTimelogForm,
    SetTimeEstimateForm,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
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
    canAddTimeEntries: {
      type: Boolean,
      required: false,
      default: true,
    },
    canSetTimeEstimate: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      timeTracking: {
        ...this.initialTimeTracking,
      },
    };
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
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
        }
        if (this.initialTimeTracking) {
          return true;
        }
        if (!this.issuableIid || !this.fullPath) {
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
    isTimeReportSupported() {
      return [TYPE_ISSUE, TYPE_MERGE_REQUEST].includes(this.issuableType) && this.issuableId;
    },
    timeEstimateTooltip() {
      return this.hasTimeEstimate
        ? s__('TimeTracking|Edit estimate')
        : s__('TimeTracking|Set estimate');
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
    refresh() {
      this.$apollo.queries.issuableTimeTracking.refetch();
    },
    openRegisterTimeSpentModal() {
      this.$root.$emit(BV_SHOW_MODAL, CREATE_TIMELOG_MODAL_ID);
    },
  },
  setTimeEstimateModalId: SET_TIME_ESTIMATE_MODAL_ID,
};
</script>

<template>
  <div v-cloak class="time-tracker sidebar-help-wrap" data-testid="time-tracker">
    <time-tracking-collapsed-state
      v-if="showCollapsed"
      :show-comparison-state="showComparisonState"
      :show-no-time-tracking-state="showNoTimeTrackingState"
      :show-spent-only-state="showSpentOnlyState"
      :show-estimate-only-state="showEstimateOnlyState"
      :time-spent-human-readable="humanTotalTimeSpent"
      :time-estimate-human-readable="humanTimeEstimate"
    />
    <div class="hide-collapsed gl-flex gl-items-center gl-font-bold gl-leading-20 gl-text-default">
      {{ __('Time tracking') }}
      <gl-loading-icon v-if="isTimeTrackingInfoLoading" size="sm" class="gl-ml-2" inline />
      <div v-if="canSetTimeEstimate || canAddTimeEntries" class="gl-ml-auto gl-flex">
        <gl-button
          v-if="canSetTimeEstimate"
          v-gl-modal="$options.setTimeEstimateModalId"
          v-gl-tooltip.top
          category="tertiary"
          icon="timer"
          size="small"
          data-testid="set-time-estimate-button"
          :title="timeEstimateTooltip"
          :aria-label="timeEstimateTooltip"
        />
        <gl-button
          v-if="canAddTimeEntries"
          v-gl-tooltip.top
          category="tertiary"
          icon="plus"
          size="small"
          data-testid="add-time-entry-button"
          :title="__('Add time entry')"
          @click="openRegisterTimeSpentModal()"
        />
      </div>
    </div>
    <div v-if="!isTimeTrackingInfoLoading" class="hide-collapsed">
      <div v-if="showEstimateOnlyState" data-testid="estimateOnlyPane">
        {{ $options.i18n.estimatedOnlyText }} {{ humanTimeEstimate }}
      </div>
      <time-tracking-spent-only-pane
        v-if="showSpentOnlyState"
        :time-spent-human-readable="humanTotalTimeSpent"
      />
      <div v-if="showNoTimeTrackingState" data-testid="noTrackingPane">
        <span class="gl-text-subtle">{{ $options.i18n.noTimeTrackingText }}</span>
      </div>
      <time-tracking-comparison-pane
        v-if="showComparisonState"
        :time-estimate="timeEstimate"
        :time-spent="totalTimeSpent"
        :time-spent-human-readable="humanTotalTimeSpent"
        :time-estimate-human-readable="humanTimeEstimate"
        :limit-to-hours="limitToHours"
      />
      <div v-if="isTimeReportSupported">
        <gl-link
          v-if="hasTotalTimeSpent"
          v-gl-modal="'time-tracking-report'"
          class="gl-text-default"
          data-testid="reportLink"
          href="#"
        >
          {{ __('Time tracking report') }}
        </gl-link>
        <gl-modal
          modal-id="time-tracking-report"
          size="lg"
          :title="__('Time tracking report')"
          :hide-footer="true"
        >
          <time-tracking-report :limit-to-hours="limitToHours" :issuable-id="issuableId" />
        </gl-modal>
      </div>
      <create-timelog-form :issuable-id="issuableId" />
      <set-time-estimate-form
        :full-path="fullPath"
        :issuable-iid="issuableIid"
        :time-tracking="timeTracking"
      />
    </div>
  </div>
</template>
