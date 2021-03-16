import Vue from 'vue';
import GlCountdown from '~/vue_shared/components/gl_countdown.vue';

const remainingTimeElements = document.querySelectorAll('.js-remaining-time');
remainingTimeElements.forEach(
  (el) =>
    new Vue({
      el,
      render(h) {
        return h(GlCountdown, {
          props: {
            endDateString: el.dateTime,
          },
        });
      },
    }),
);
