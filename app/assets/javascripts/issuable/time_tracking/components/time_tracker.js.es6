/* global Vue */

require('./help_state');
require('./collapsed_state');
require('./spent_only_pane');
require('./no_tracking_pane');
require('./estimate_only_pane');
require('./comparison_pane');

(() => {
  Vue.component('issuable-time-tracker', {
    name: 'issuable-time-tracker',
    props: [
      'time_estimate',
      'time_spent',
      'human_time_estimate',
      'human_time_spent',
      'docsUrl',
    ],
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
    methods: {
      toggleHelpState(show) {
        this.showHelp = show;
      },
    },
    template: `
      <div class='time_tracker time-tracking-component-wrap' v-cloak>
        <time-tracking-collapsed-state
          :show-comparison-state='showComparisonState'
          :show-help-state='showHelpState'
          :show-spent-only-state='showSpentOnlyState'
          :show-estimate-only-state='showEstimateOnlyState'
          :time-spent-human-readable='timeSpentHumanReadable'
          :time-estimate-human-readable='timeEstimateHumanReadable'>
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
            :time-estimate-human-readable='timeEstimateHumanReadable'>
          </time-tracking-estimate-only-pane>
          <time-tracking-spent-only-pane
            v-if='showSpentOnlyState'
            :time-spent-human-readable='timeSpentHumanReadable'>
          </time-tracking-spent-only-pane>
          <time-tracking-no-tracking-pane
            v-if='showNoTimeTrackingState'>
          </time-tracking-no-tracking-pane>
          <time-tracking-comparison-pane
            v-if='showComparisonState'
            :time-estimate='timeEstimate'
            :time-spent='timeSpent'
            :time-spent-human-readable='timeSpentHumanReadable'
            :time-estimate-human-readable='timeEstimateHumanReadable'>
          </time-tracking-comparison-pane>
          <transition name='help-state-toggle'>
            <time-tracking-help-state
              v-if='showHelpState'
              :docs-url='docsUrl'>
            </time-tracking-help-state>
          </transition>
        </div>
      </div>
    `,
  });
})();
