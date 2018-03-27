<script>
import timeTrackingHelpState from './help_state';
import TimeTrackingCollapsedState from './collapsed_state.vue';
import timeTrackingSpentOnlyPane from './spent_only_pane';
import timeTrackingNoTrackingPane from './no_tracking_pane';
import timeTrackingEstimateOnlyPane from './estimate_only_pane';
import timeTrackingComparisonPane from './comparison_pane';

import eventHub from '../../event_hub';

export default {
  name: 'IssuableTimeTracker',
  components: {
    TimeTrackingCollapsedState,
    'time-tracking-estimate-only-pane': timeTrackingEstimateOnlyPane,
    'time-tracking-spent-only-pane': timeTrackingSpentOnlyPane,
    'time-tracking-no-tracking-pane': timeTrackingNoTrackingPane,
    'time-tracking-comparison-pane': timeTrackingComparisonPane,
    'time-tracking-help-state': timeTrackingHelpState,
  },
  props: {
    time_estimate: {
      type: Number,
      required: true,
    },
    time_spent: {
      type: Number,
      required: true,
    },
    human_time_estimate: {
      type: String,
      required: false,
      default: '',
    },
    human_time_spent: {
      type: String,
      required: false,
      default: '',
    },
    rootPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      showHelp: false,
    };
  },
  computed: {
    timeSpent() {
      return this.time_spent;
    },
    timeEstimate() {
      return this.time_estimate;
    },
    timeEstimateHumanReadable() {
      return this.human_time_estimate;
    },
    timeSpentHumanReadable() {
      return this.human_time_spent;
    },
    hasTimeSpent() {
      return !!this.timeSpent;
    },
    hasTimeEstimate() {
      return !!this.timeEstimate;
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
      return !!this.showHelp;
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
      this.time_estimate = data.time_estimate;
      this.time_spent = data.time_spent;
      this.human_time_estimate = data.human_time_estimate;
      this.human_time_spent = data.human_time_spent;
    },
  },
};
</script>

<template>
  <div
    class="time_tracker time-tracking-component-wrap"
    v-cloak
  >
    <time-tracking-collapsed-state
      :show-comparison-state="showComparisonState"
      :show-no-time-tracking-state="showNoTimeTrackingState"
      :show-help-state="showHelpState"
      :show-spent-only-state="showSpentOnlyState"
      :show-estimate-only-state="showEstimateOnlyState"
      :time-spent-human-readable="timeSpentHumanReadable"
      :time-estimate-human-readable="timeEstimateHumanReadable"
    />
    <div class="title hide-collapsed">
      {{ __('Time tracking') }}
      <div
        class="help-button pull-right"
        v-if="!showHelpState"
        @click="toggleHelpState(true)"
      >
        <i
          class="fa fa-question-circle"
          aria-hidden="true"
        >
        </i>
      </div>
      <div
        class="close-help-button pull-right"
        v-if="showHelpState"
        @click="toggleHelpState(false)"
      >
        <i
          class="fa fa-close"
          aria-hidden="true"
        >
        </i>
      </div>
    </div>
    <div class="time-tracking-content hide-collapsed">
      <time-tracking-estimate-only-pane
        v-if="showEstimateOnlyState"
        :time-estimate-human-readable="timeEstimateHumanReadable"
      />
      <time-tracking-spent-only-pane
        v-if="showSpentOnlyState"
        :time-spent-human-readable="timeSpentHumanReadable"
      />
      <time-tracking-no-tracking-pane
        v-if="showNoTimeTrackingState"
      />
      <time-tracking-comparison-pane
        v-if="showComparisonState"
        :time-estimate="timeEstimate"
        :time-spent="timeSpent"
        :time-spent-human-readable="timeSpentHumanReadable"
        :time-estimate-human-readable="timeEstimateHumanReadable"
      />
      <transition name="help-state-toggle">
        <time-tracking-help-state
          v-if="showHelpState"
          :root-path="rootPath"
        />
      </transition>
    </div>
  </div>
</template>
