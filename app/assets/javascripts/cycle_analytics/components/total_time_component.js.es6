((global) => {
  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.TotalTimeComponent = Vue.extend({
    props: {
      time: Object,
    },
    template: `
      <span>
        <span class="days" v-if="time.days">
          {{ time.days }}
          <abbr title="Days">{{ time.days === 1 ? 'day' : 'days' }}</abbr>
        </span>
        <span class="hours" v-if="time.hours">
          {{ time.hours }}
          <abbr title="Hours">hr</abbr>
        </span>
        <span class="mins" v-if="time.mins">
          {{ time.mins }}
          <abbr title="Minutes">mins</abbr>
        </span>
        <span class="seconds hide" v-if="time.seconds">
          {{ time.seconds }}
          <abbr title="Seconds">s</abbr>
        </span>
      </span>
    `,
  });
})(window.gl || (window.gl = {}));
