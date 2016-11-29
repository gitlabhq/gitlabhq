/* eslint-disable no-param-reassign */
/* global Vue */

((global) => {
  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.TotalTimeComponent = Vue.extend({
    props: {
      time: Object,
    },
    template: `
      <span class="total-time">
        <template v-if="time.days">{{ time.days }} <span>{{ time.days === 1 ? 'day' : 'days' }}</span></template>
        <template v-if="time.hours">{{ time.hours }} <span>hr</span></template>
        <template v-if="time.mins && !time.days">{{ time.mins }} <span>mins</span></template>
        <template v-if="time.seconds && Object.keys(time).length === 1 || time.seconds === 0">{{ time.seconds }} <span>s</span></template>
      </span>
    `,
  });
})(window.gl || (window.gl = {}));
