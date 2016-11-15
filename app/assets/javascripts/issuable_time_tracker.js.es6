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
        initPolling() {
          new gl. TODO:SmartInterval({
            callback: this.fetchIssuable,
            startingInterval: 1000,
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
        $(document).on('ajax:success', '.gfm-form', (e) => {
          // TODO: check if slash command was included.
          this.fetchIssuable();
        });
      },
      mounted() {
        gl.IssuableResource.subscribe(data => this.updateState(data));
        this.initPolling();
      }
    });
  });

  Vue.component('issuable-time-tracker', {
    props: ['time_estimated', 'time_spent'],
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
              <div class='compare-meter' data-toggle='tooltip' data-placement='top' v-tooltip-title='remainingTooltipPretty' >
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
    data: function() {
      return {
        displayHelp: false,
        loading: false,
      }
    },
    computed: {
      showComparison() {
        return !!this.time_estimated && !!this.time_spent;
      },
      showEstimateOnly() {
        return !!this.time_estimated && !this.time_spent;
      },
      showSpentOnly() {
        return !!this.time_spent && !this.time_estimated;
      },
      showNoTimeTracking() {
        return !this.time_estimated && !this.time_spent;
      },
      showHelp() {
        return !!this.displayHelp;
      },
      estimatedPretty() {
        return this.stringifyTime(this.time_estimated);
      },
      spentPretty() {
        return this.stringifyTime(this.time_spent);
      },
      remainingPretty() {
        return this.stringifyTime(this.parsedDiff);
      },
      remainingTooltipPretty() {
        const prefix = this.diffMinutes < 0 ? 'Over by' : 'Time remaining:';
        return `${prefix} ${this.remainingPretty}`;
      },
      parsedDiff () {
        const MAX_DAYS = 5, MAX_HOURS = 8, MAX_MINUTES = 60;
        const timePeriodConstraints = [
          [ 'weeks', MAX_HOURS * MAX_DAYS ],
          [ 'days', MAX_MINUTES * MAX_HOURS ],
          [ 'hours', MAX_MINUTES ],
          [ 'minutes', 1 ]
        ];

        const parsedDiff = {};

        let unorderedMinutes = Math.abs(this.diffMinutes);

        timePeriodConstraints.forEach((period, idx, collection) => {
          const periodName = period[0];
          const minutesPerPeriod = period[1];
          const periodCount = Math.floor(unorderedMinutes / minutesPerPeriod);

          unorderedMinutes -= (periodCount * minutesPerPeriod);
          parsedDiff[periodName] = periodCount;
        });

        return parsedDiff;
      },
      diffMinutes () {
        const time_estimated = this.time_estimated;
        const time_spent = this.time_spent;
        return time_estimated.totalMinutes - time_spent.totalMinutes;
      },
      diffPercent() {
        const estimate = this.estimate;
        return Math.floor((this.time_spent.totalMinutes / this.time_estimated.totalMinutes * 100)) + '%';
      },
      diffStatus() {
        return this.time_estimated.totalMinutes >= this.time_spent.totalMinutes ? 'within_estimate' : 'over_estimate';
      }
    },
    methods: {
      abbreviateTime(value) {
        return value.split(' ')[0];
      },
      toggleHelpState(show) {
        this.displayHelp = show;
      },
      stringifyTime(obj) {
        return _.reduce(obj, (memo, val, key) => {
          return (key !== 'totalMinutes' && val !== 0) ? (memo + `${val}${key.charAt(0)} `) : memo;
        }, '').trim();
      },
    },
  });
}) (window.gl || (window.gl = {}));
