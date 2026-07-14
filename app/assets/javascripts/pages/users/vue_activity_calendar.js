import Vue from 'vue';

export const initVueActivityCalendar = () => {
  const el = document.getElementById('js-vue-activity-calendar');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    name: 'VueActivityCalendarRoot',
    render(createElement) {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return createElement('div', { class: 'new-activities-block' }, 'Temporary placeholder');
    },
  });
};
