//= require lib/utils/pretty_time

((gl) => {
  const PrettyTime = gl.PrettyTime;

  Vue.component('time-tracking-comparison-pane', {
    name: 'time-tracking-comparison-pane',
    props: ['timeSpent', 'timeEstimate', 'timeSpentHuman', 'timeEstimateHuman'],
    computed: {
      parsedRemaining() {
        const diffSeconds = this.timeEstimate - this.timeSpent;
        return PrettyTime.parseSeconds(diffSeconds);
      },
      timeRemainingHuman() {
        return PrettyTime.stringifyTime(this.parsedRemaining);
      },
      timeRemainingTooltip() {
        const prefix = this.timeRemainingMinutes < 0 ? 'Over by' : 'Time remaining:';
        return `${prefix} ${this.timeRemainingHuman}`;
      },

      /* Diff values for comparison meter */
      timeRemainingMinutes() {
        return this.timeEstimate - this.timeSpent;
      },
      timeRemainingPercent() {
        return `${Math.floor(((this.timeSpent / this.timeEstimate) * 100))}%`;
      },
      timeRemainingStatusClass() {
        return this.timeEstimate >= this.timeSpent ? 'within_estimate' : 'over_estimate';
      },
      /* Parsed time values */
      parsedEstimate() {
        return PrettyTime.parseSeconds(this.timeEstimate);
      },
      parsedSpent() {
        return PrettyTime.parseSeconds(this.timeSpent);
      },
    },
    template: `
      <div class='time-tracking-comparison-pane'>
        <div class='compare-meter' data-toggle='tooltip' data-placement='top' role='timeRemainingDisplay'
          :aria-valuenow='timeRemainingTooltip'
          :title='timeRemainingTooltip'
          :data-original-title='timeRemainingTooltip'
          :class='timeRemainingStatusClass'>
          <div class='meter-container' role='timeSpentPercent' :aria-valuenow='timeRemainingPercent'>
            <div :style='{ width: timeRemainingPercent }' class='meter-fill'></div>
          </div>
          <div class='compare-display-container'>
            <div class='compare-display pull-left'>
              <span class='compare-label'>Spent</span>
              <span class='compare-value spent'>{{ timeSpentHuman }}</span>
            </div>
            <div class='compare-display estimated pull-right'>
              <span class='compare-label'>Est</span>
              <span class='compare-value'>{{ timeEstimateHuman }}</span>
            </div>
          </div>
        </div>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
