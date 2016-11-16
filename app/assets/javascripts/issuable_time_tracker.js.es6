//= vue

(() => {
  gl.IssuableTimeTracker = Vue.component('issuable-time-tracker', {
    name: 'issuable-time-tracker',
    props: ['time_estimate', 'time_spent', 'human_time_estimate', 'human_time_spent'],
    data() {
      return {
        displayHelp: false,
      };
    },
    computed: {
      /* Select panels to show */
      showComparison() {
        return !!this.time_estimate && !!this.time_spent;
      },
      showEstimateOnly() {
        return !!this.time_estimate && !this.time_spent;
      },
      showSpentOnly() {
        return !!this.time_spent && !this.time_estimate;
      },
      showNoTimeTracking() {
        return !this.time_estimate && !this.time_spent;
      },
      showHelp() {
        return !!this.displayHelp;
      },

      /* Parsed time values */
      parsedEstimate() {
        return this.parseSeconds(this.time_estimate);
      },
      parsedSpent() {
        return this.parseSeconds(this.time_spent);
      },
      parsedRemaining() {
        const diffSeconds = this.time_estimate - this.time_spent;
        return this.parseSeconds(diffSeconds);
      },

      /* Human readable time values */
      estimatedPretty() {
        return this.human_time_estimate || this.stringifyTime(this.parsedEstimate);
      },
      spentPretty() {
        return this.human_time_spent || this.stringifyTime(this.parsedSpent);
      },
      remainingPretty() {
        return this.stringifyTime(this.parsedRemaining);
      },
      remainingTooltipPretty() {
        const prefix = this.diffMinutes < 0 ? 'Over by' : 'Time remaining:';
        return `${prefix} ${this.remainingPretty}`;
      },

      /* Diff values for comparison meter */
      diffMinutes() {
        return this.time_estimate - this.time_spent;
      },
      diffPercent() {
        return `${Math.floor(((this.time_spent / this.time_estimate) * 100))}%`;
      },
      diffStatusClass() {
        return this.time_estimate >= this.time_spent ? 'within_estimate' : 'over_estimate';
      },
    },
    methods: {
      secondsToMinutes(seconds) {
        return Math.abs(seconds / 60);
      },
      parseSeconds(seconds) {
        const DAYS_PER_WEEK = 5;
        const HOURS_PER_DAY = 8;
        const MINUTES_PER_HOUR = 60;
        const MINUTES_PER_WEEK = DAYS_PER_WEEK * HOURS_PER_DAY * MINUTES_PER_HOUR;
        const MINUTES_PER_DAY = HOURS_PER_DAY * MINUTES_PER_HOUR;

        const timePeriodConstraints = {
          weeks: MINUTES_PER_WEEK,
          days: MINUTES_PER_DAY,
          hours: MINUTES_PER_HOUR,
          minutes: 1,
        };

        let unorderedMinutes = this.secondsToMinutes(seconds);

        return _.mapObject(timePeriodConstraints, (minutesPerPeriod) => {
          const periodCount = Math.floor(unorderedMinutes / minutesPerPeriod);

          unorderedMinutes -= (periodCount * minutesPerPeriod);

          return periodCount;
        });
      },
      abbreviateTime(value) {
        return value.split(' ')
          .filter(unitStr => unitStr.charAt(0) !== '0')[0];
      },
      toggleHelpState(show) {
        this.displayHelp = show;
      },
      stringifyTime(obj) {
        const reducedTime = _.reduce(obj, (memo, unitValue, unitName) => {
          const isNonZero = !!unitValue;
          return isNonZero ? `${memo} ${unitValue}${unitName.charAt(0)} ` : memo;
        }, '').trim();
        return reducedTime.length ? reducedTime : '0m';
      },
    },
    template: `
        <div class='time-tracking-component-wrap' v-cloak>
          <div class='sidebar-collapsed-icon'>
            <slot name='stopwatch'></slot>
            <div class='time-tracking-collapsed-summary'>
              <div class='compare' v-if='showComparison'>
                <span>{{ abbreviateTime(spentPretty) }} / {{ abbreviateTime(estimatedPretty) }}</span>
              </div>
              <div class='estimate-only' v-if='showEstimateOnly'>
                <span class='bold'>-- / {{ abbreviateTime(estimatedPretty) }}</span>
              </div>
              <div class='spend-only' v-if='showSpentOnly'>
                <span class='bold'>{{ abbreviateTime(spentPretty) }} / --</span>
              </div>
              <div class='no-tracking' v-if='showNoTimeTracking'>
                <span class='no-value'>None</span>
              </div>
            </div>
          </div>
          <div class='title hide-collapsed'>
            Time tracking
            <div class='help-button pull-right' v-if='!showHelp' v-on:click='toggleHelpState(true)'>
              <i class='fa fa-question-circle'></i>
            </div>
          </div>
          <div class='time-tracking-content hide-collapsed'>
            <div class='time-tracking-pane-compare' v-if='showComparison'>
              <div class='compare-meter' data-toggle='tooltip' data-placement='top' v-tooltip-title='remainingTooltipPretty' :class='diffStatusClass' >
                <div class='meter-container'>
                  <div :style='{ width: diffPercent }' class='meter-fill'></div>
                </div>
                <div class='compare-display-container'>
                  <div class='compare-display pull-left'>
                    <span class='compare-label'>Spent</span>
                    <span class='compare-value spent'>{{ spentPretty }}</span>
                  </div>
                  <div class='compare-display estimated pull-right'>
                    <span class='compare-label'>Est</span>
                    <span class='compare-value'>{{ estimatedPretty }}</span>
                  </div>
                </div>
              </div>
            </div>
            <div class='time-tracking-estimate-only' v-if='showEstimateOnly'>
              <span class='bold'>Estimated:</span>
              {{ estimatedPretty }}
            </div>
            <div class='time-tracking-spend-only' v-if='showSpentOnly'>
              <span class='bold'>Spent:</span>
              {{ spentPretty }}
            </div>
            <div class='time-tracking-no-tracking' v-if='showNoTimeTracking'>
              <span class='no-value'>No estimate or time spent</span>
            </div>
            <div class='time-tracking-help-state' v-if='showHelp'>
              <div class='close-help-button pull-right' v-on:click='toggleHelpState(false)'>
                <i class='fa fa-close'></i>
              </div>
              <div class='time-tracking-info'>
                <h4>Track time with slash commands</h4>
                <p>Slash commands can be used in the issues description and comment boxes.</p>
                <p>
                  <code>/estimate</code>
                  will update the estimated time with the latest command.
                </p>
                <p>
                  <code>/spend</code>
                  will update the sum of the time spent.
                </p>
                <a class='btn btn-default learn-more-button' href='http://example.com/time-tracking-url'> Learn more </a>
              </div>
            </div>
          </div>
        </div>
    `,
  });
})(window.gl || (window.gl = {}));
