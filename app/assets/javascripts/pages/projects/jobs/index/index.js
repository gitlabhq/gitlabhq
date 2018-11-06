import Vue from 'vue';
import GlCountdown from '~/vue_shared/components/gl_countdown.vue';

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
});
