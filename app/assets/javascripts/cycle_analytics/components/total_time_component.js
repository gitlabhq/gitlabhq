/* eslint-disable no-param-reassign */

import Vue from 'vue';

const global = window.gl || (window.gl = {});
global.cycleAnalytics = global.cycleAnalytics || {};

global.cycleAnalytics.TotalTimeComponent = Vue.extend({
  props: {
    time: Object,
  },
  template: `
    <span class="total-time">
      <template v-if="Object.keys(time).length">
        <template v-if="time.days">{{ time.days }} <span>{{ n__('day', 'days', time.days) }}</span></template>
        <template v-if="time.hours">{{ time.hours }} <span>{{ n__('Time|hr', 'Time|hrs', time.hours) }}</span></template>
        <template v-if="time.mins && !time.days">{{ time.mins }} <span>{{ n__('Time|min', 'Time|mins', time.mins) }}</span></template>
        <template v-if="time.seconds && Object.keys(time).length === 1 || time.seconds === 0">{{ time.seconds }} <span>{{ s__('Time|s') }}</span></template>
      </template>
      <template v-else>
        --
      </template>
    </span>
  `,
});
