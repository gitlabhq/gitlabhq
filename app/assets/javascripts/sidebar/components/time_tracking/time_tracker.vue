<script>
import { GlIcon, GlLink, GlModal, GlModalDirective } from '@gitlab/ui';
import { s__, __ } from '~/locale';
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
    TimeTrackingCollapsedState,
    TimeTrackingSpentOnlyPane,
    TimeTrackingComparisonPane,
    TimeTrackingHelpState,
    TimeTrackingReport,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    timeEstimate: {
      type: Number,
      required: true,
    },
    timeSpent: {
      type: Number,
      required: true,
    },
    humanTimeEstimate: {
      type: String,
      required: false,
      default: '',
    },
    humanTimeSpent: {
      type: String,
      required: false,
      default: '',
    },
    limitToHours: {
      type: Boolean,
      default: false,
      required: false,
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
    };
  },
  computed: {
    hasTimeSpent() {
      return Boolean(this.timeSpent);
    },
    hasTimeEstimate() {
      return Boolean(this.timeEstimate);
    },
    showComparisonState() {
      return this.hasTimeEstimate && this.hasTimeSpent;
    },
    showEstimateOnlyState() {
      return this.hasTimeEstimate && !this.hasTimeSpent;
    },
    showSpentOnlyState() {
      return this.hasTimeSpent && !this.hasTimeEstimate;
    },
    showNoTimeTrackingState() {
      return !this.hasTimeEstimate && !this.hasTimeSpent;
    },
    showHelpState() {
      return Boolean(this.showHelp);
    },
  },
  created() {
    eventHub.$on('timeTracker:updateData', this.update);
  },
  methods: {
    toggleHelpState(show) {
      this.showHelp = show;
    },
    update(data) {
      const { timeEstimate, timeSpent, humanTimeEstimate, humanTimeSpent } = data;

      /* eslint-disable vue/no-mutating-props */
      this.timeEstimate = timeEstimate;
      this.timeSpent = timeSpent;
      this.humanTimeEstimate = humanTimeEstimate;
      this.humanTimeSpent = humanTimeSpent;
      /* eslint-enable vue/no-mutating-props */
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
      :time-spent-human-readable="humanTimeSpent"
      :time-estimate-human-readable="humanTimeEstimate"
    />
    <div class="title hide-collapsed gl-mb-3">
      {{ __('Time tracking') }}
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
    <div class="time-tracking-content hide-collapsed">
      <div v-if="showEstimateOnlyState" data-testid="estimateOnlyPane">
        <span class="gl-font-weight-bold">{{ $options.i18n.estimatedOnlyText }} </span
        >{{ humanTimeEstimate }}
      </div>
      <time-tracking-spent-only-pane
        v-if="showSpentOnlyState"
        :time-spent-human-readable="humanTimeSpent"
      />
      <div v-if="showNoTimeTrackingState" data-testid="noTrackingPane">
        <span class="gl-text-gray-500">{{ $options.i18n.noTimeTrackingText }}</span>
      </div>
      <time-tracking-comparison-pane
        v-if="showComparisonState"
        :time-estimate="timeEstimate"
        :time-spent="timeSpent"
        :time-spent-human-readable="humanTimeSpent"
        :time-estimate-human-readable="humanTimeEstimate"
        :limit-to-hours="limitToHours"
      />
      <gl-link
        v-if="hasTimeSpent"
        v-gl-modal="'time-tracking-report'"
        data-testid="reportLink"
        href="#"
        class="btn-link"
        >{{ __('Time tracking report') }}</gl-link
      >
      <gl-modal
        modal-id="time-tracking-report"
        :title="__('Time tracking report')"
        :hide-footer="true"
      >
        <time-tracking-report :limit-to-hours="limitToHours" />
      </gl-modal>
      <transition name="help-state-toggle">
        <time-tracking-help-state v-if="showHelpState" />
      </transition>
    </div>
  </div>
</template>
