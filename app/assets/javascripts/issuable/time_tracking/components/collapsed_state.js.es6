/* global Vue */
import stopwatchSvg from '../../../../../views/shared/icons/_icon_stopwatch.svg';

require('../../../lib/utils/pretty_time');

(() => {
  Vue.component('time-tracking-collapsed-state', {
    name: 'time-tracking-collapsed-state',
    props: [
      'showComparisonState',
      'showSpentOnlyState',
      'showEstimateOnlyState',
      'showNoTimeTrackingState',
      'timeSpentHumanReadable',
      'timeEstimateHumanReadable',
    ],
    methods: {
      abbreviateTime(timeStr) {
        return gl.utils.prettyTime.abbreviateTime(timeStr);
      },
    },
    template: `
      <div class='sidebar-collapsed-icon'>
        ${stopwatchSvg}
        <div class='time-tracking-collapsed-summary'>
          <div class='compare' v-if='showComparisonState'>
            <span>{{ abbreviateTime(timeSpentHumanReadable) }} / {{ abbreviateTime(timeEstimateHumanReadable) }}</span>
          </div>
          <div class='estimate-only' v-if='showEstimateOnlyState'>
            <span class='bold'>-- / {{ abbreviateTime(timeEstimateHumanReadable) }}</span>
          </div>
          <div class='spend-only' v-if='showSpentOnlyState'>
            <span class='bold'>{{ abbreviateTime(timeSpentHumanReadable) }} / --</span>
          </div>
          <div class='no-tracking' v-if='showNoTimeTrackingState'>
            <span class='no-value'>None</span>
          </div>
        </div>
      </div>
      `,
  });
})();
