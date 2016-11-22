//= require vue
(() => {
  gl.IssuableTimeTracker = Vue.component('issuable-time-tracker', {
    name: 'issuable-time-tracker',
    props: ['time_estimate', 'time_spent', 'human_time_estimate', 'human_time_spent', 'stopwatchSvg'],
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
      timeEstimateHuman() {
        return this.human_time_estimate;
      },
      timeSpentHuman() {
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
    methods: {
      toggleHelpState(show) {
        this.showHelp = show;
      },
    },
    template: `
      <div class='time_tracker time-tracking-component-wrap' v-cloak>
        <time-tracking-collapsed-state
          :showComparisonState='showComparisonState'
          :showHelpState='showHelpState'
          :showSpentOnlyState='showSpentOnlyState'
          :showEstimateOnlyState='showEstimateOnlyState'
          :timeSpentHuman='timeSpentHuman'
          :timeEstimateHuman='timeEstimateHuman'
          :stopwatch-svg='stopwatchSvg'>
        </time-tracking-collapsed-state>
        <div class='title hide-collapsed'>
          Time tracking
          <div class='help-button pull-right'
            v-if='!showHelpState'
            @click='toggleHelpState(true)'>
            <i class='fa fa-question-circle'></i>
          </div>
          <div class='close-help-button pull-right'
            v-if='showHelpState'
            @click='toggleHelpState(false)'>
            <i class='fa fa-close'></i>
          </div>
        </div>
        <div class='time-tracking-content hide-collapsed'>
          <time-tracking-estimate-only-pane
            v-if='showEstimateOnlyState'
            :timeEstimateHuman='timeEstimateHuman'>
          </time-tracking-estimate-only-pane>
          <time-tracking-spent-only-pane
            v-if='showSpentOnlyState'
            :timeSpentHuman='timeSpentHuman'>
          </time-tracking-spent-only-pane>
          <time-tracking-no-tracking-pane
            v-if='showNoTimeTrackingState'>
          </time-tracking-no-tracking-pane>
          <time-tracking-comparison-pane
            v-if='showComparisonState'
            :timeEstimate='timeEstimate'
            :timeSpent='timeSpent'
            :timeSpentHuman='timeSpentHuman'
            :timeEstimateHuman='timeEstimateHuman'>
          </time-tracking-comparison-pane>
          <transition name='help-state-toggle'>
            <time-tracking-help-state
              v-if='showHelpState'>
            </time-tracking-help-state>
          </transition>
        </div>
      </div>
    `,
  });
})();
