import Vue from 'vue';
import initJobsTable from '~/jobs/components/table';
import GlCountdown from '~/vue_shared/components/gl_countdown.vue';

if (gon.features?.jobsTableVue) {
  initJobsTable();
} else {
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
}
