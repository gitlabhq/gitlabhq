import Vue from 'vue';
import MergeScheduleInput from '~/merge_requests/components/merge_schedule_input.vue';

export default () => {
  const el = document.querySelector('.js-merge-request-schedule-input');

  if (!el) return false;

  const { mergeAfter, paramKey } = el.dataset;

  return new Vue({
    el,
    render(h) {
      return h(MergeScheduleInput, {
        props: {
          mergeAfter,
          paramKey,
        },
      });
    },
  });
};
