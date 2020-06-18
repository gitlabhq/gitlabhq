<script>
import TimeTrackingHelpState from './help_state.vue';
import TimeTrackingCollapsedState from './collapsed_state.vue';
import TimeTrackingSpentOnlyPane from './spent_only_pane.vue';
import TimeTrackingNoTrackingPane from './no_tracking_pane.vue';
import TimeTrackingEstimateOnlyPane from './estimate_only_pane.vue';
import TimeTrackingComparisonPane from './comparison_pane.vue';

import eventHub from '../../event_hub';

export default {
  name: 'IssuableTimeTracker',
  components: {
    TimeTrackingCollapsedState,
    TimeTrackingEstimateOnlyPane,
    TimeTrackingSpentOnlyPane,
    TimeTrackingNoTrackingPane,
    TimeTrackingComparisonPane,
    TimeTrackingHelpState,
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

      this.timeEstimate = timeEstimate;
      this.timeSpent = timeSpent;
      this.humanTimeEstimate = humanTimeEstimate;
      this.humanTimeSpent = humanTimeSpent;
    },
  },
};
</script>

<template>
  <div v-cloak class="time_tracker time-tracking-component-wrap">
    <time-tracking-collapsed-state
      :show-comparison-state="showComparisonState"
      :show-no-time-tracking-state="showNoTimeTrackingState"
      :show-help-state="showHelpState"
      :show-spent-only-state="showSpentOnlyState"
      :show-estimate-only-state="showEstimateOnlyState"
      :time-spent-human-readable="humanTimeSpent"
      :time-estimate-human-readable="humanTimeEstimate"
    />
    <div class="title hide-collapsed">
      {{ __('Time tracking') }}
      <div v-if="!showHelpState" class="help-button float-right" @click="toggleHelpState(true)">
        <i class="fa fa-question-circle" aria-hidden="true"> </i>
      </div>
      <div
        v-if="showHelpState"
        class="close-help-button float-right"
        @click="toggleHelpState(false)"
      >
        <i class="fa fa-close" aria-hidden="true"> </i>
      </div>
    </div>
    <div class="time-tracking-content hide-collapsed">
      <time-tracking-estimate-only-pane
        v-if="showEstimateOnlyState"
        :time-estimate-human-readable="humanTimeEstimate"
      />
      <time-tracking-spent-only-pane
        v-if="showSpentOnlyState"
        :time-spent-human-readable="humanTimeSpent"
      />
      <time-tracking-no-tracking-pane v-if="showNoTimeTrackingState" />
      <time-tracking-comparison-pane
        v-if="showComparisonState"
        :time-estimate="timeEstimate"
        :time-spent="timeSpent"
        :time-spent-human-readable="humanTimeSpent"
        :time-estimate-human-readable="humanTimeEstimate"
        :limit-to-hours="limitToHours"
      />
      <transition name="help-state-toggle">
        <time-tracking-help-state v-if="showHelpState" />
      </transition>
    </div>
  </div>
</template>
