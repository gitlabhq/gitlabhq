import Vue from 'vue';
import GlCountdown from '~/vue_shared/components/gl_countdown.vue';
import Tracking from '~/tracking';

document.addEventListener('DOMContentLoaded', () => {
  const remainingTimeElements = document.querySelectorAll('.js-remaining-time');
  remainingTimeElements.forEach(
    el =>
      new Vue({
        ...GlCountdown,
        el,
        propsData: {
          endDateString: el.dateTime,
        },
      }),
  );

  const trackButtonClick = () => {
    if (gon.tracking_data) {
      const { category, action, ...data } = gon.tracking_data;
      Tracking.event(category, action, data);
    }
  };
  const buttons = document.querySelectorAll('.js-empty-state-button');
  buttons.forEach(button => button.addEventListener('click', trackButtonClick));
});
