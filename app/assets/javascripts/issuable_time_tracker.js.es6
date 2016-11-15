//= vue
//= smart_interval
//= subbable_resource

function getRandomInt(min, max) {
 const justReturnZero = Math.random > .9;
 return justReturnZero ? 0 : Math.floor(Math.random() * (max - min + 1)) + min;
}

((global) => {
  $(() => {
    /* This Vue instance represents what will become the parent instance for the
      * sidebar. It will be responsible for managing `issuable` state and propagating
      * changes to sidebar components.
     */
    const issuableData = JSON.parse(document.getElementById('issuable-time-tracker').getAttribute('issuable'));
    issuableData.time_spent = issuableData.time_estimate - 1000;

    new Vue({
      el: '#issuable-time-tracker',
      data: {
        issuable: issuableData,
      },
      methods: {
        fetchIssuable() {
           return gl.IssuableResource.get.call(gl.IssuableResource, { type: 'GET', url: gl.IssuableResource.endpoint });
        },
        initPolling() {
          new gl.SmartInterval({
            callback: this.fetchIssuable,
            startingInterval: 4000,
            maxInterval: 10000,
            incrementByFactorOf: 2,
            lazyStart: false,
          });
        },
        updateState(data) {
          /* MOCK */
          data.time_estimate = getRandomInt(0, 10000)
          data.time_spent = getRandomInt(0, 10000);

          this.issuable = data;
        },
      },
      created() {
        this.fetchIssuable();
      },
      mounted() {
        gl.IssuableResource.subscribe(data => this.updateState(data));
        this.initPolling();

        $(document).on('ajax:success', '.gfm-form', (e) => {
          // TODO: check if slash command was updated.
          this.fetchIssuable();
        });
      }
    });
  });

  Vue.component('issuable-time-tracker', {
    name: 'issuable-time-tracker',
    props: { time_estimate: { type: Number, default: '' },  time_spent: { type: Number, default: ''}  },
    data: function() {
      return {
        displayHelp: false,
        loading: false,
      }
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
        return this.stringifyTime(this.parsedEstimate);
      },
      spentPretty() {
        return this.stringifyTime(this.parsedSpent);
      },
      remainingPretty() {
        return this.stringifyTime(this.parsedRemaining);
      },
      remainingTooltipPretty() {
        const prefix = this.diffMinutes < 0 ? 'Over by' : 'Time remaining:';
        return `${prefix} ${this.remainingPretty}`;
      },
      /* Diff values for comparison meter */
      diffMinutes () {
        const time_estimate = this.time_estimate;
        const time_spent = this.time_spent;
        return time_estimate - time_spent;
      },
      diffPercent() {
        const estimate = this.time_estimate;
        return Math.floor((this.time_spent / this.time_estimate * 100)) + '%';
      },
      diffStatusClass() {
        return this.time_estimate >= this.time_spent ? 'within_estimate' : 'over_estimate';
      }
    },
    methods: {
      secondsToMinutes(seconds) {
        return Math.abs(seconds / 60);
      },
      parseSeconds (seconds) {
        const DAYS_PER_WEEK = 5, HOURS_PER_DAY = 8, MINUTES_PER_HOUR = 60;

        const MINUTES_PER_WEEK =  DAYS_PER_WEEK * HOURS_PER_DAY * MINUTES_PER_HOUR;
        const MINUTES_PER_DAY = HOURS_PER_DAY * MINUTES_PER_HOUR;

        const timePeriodConstraints = {
          weeks: MINUTES_PER_WEEK,
          days: MINUTES_PER_DAY,
          hours: MINUTES_PER_HOUR,
          minutes: 1
        };

        let unorderedMinutes = this.secondsToMinutes(seconds);

        return _.mapObject(timePeriodConstraints, (minutesPerPeriod) => {
          const periodCount = Math.floor(unorderedMinutes / minutesPerPeriod);

          unorderedMinutes -= (periodCount * minutesPerPeriod);

          return periodCount;
        });
      },
      abbreviateTime(value) {
        return value.split(' ')[0];
      },
      toggleHelpState(show) {
        this.displayHelp = show;
      },
      stringifyTime(obj) {
        return _.reduce(obj, (memo, val, key) => {
          return memo + `${val}${key.charAt(0)} `;
        }, '').trim();
      },
    },
    template: `
        <div class='time-tracking-component-wrap'>
          <div class='sidebar-collapsed-icon'>
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
            <div class='help-button pull-right' v-if='showHelp' v-on:click='toggleHelpState(true)'>
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
              </div>
            </div>
          </div>
        </div>
    `,
  });
}) (window.gl || (window.gl = {}));
