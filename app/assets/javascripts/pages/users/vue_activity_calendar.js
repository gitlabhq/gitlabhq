import Vue from 'vue';
import ActivityCalendar from '~/profile/components/activity_calendar.vue';

export const initVueActivityCalendar = () => {
  const el = document.getElementById('js-vue-activity-calendar');

  if (!el) {
    return null;
  }

  const { utcOffset } = el.dataset;

  return new Vue({
    el,
    name: 'VueActivityCalendarRoot',
    provide: {
      utcOffset,
    },
    render(createElement) {
      return createElement(ActivityCalendar);
    },
  });
};
