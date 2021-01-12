import Vue from 'vue';
import PipelineSchedulesCallout from '../shared/components/pipeline_schedules_callout.vue';

document.addEventListener('DOMContentLoaded', () => {
  const el = document.getElementById('pipeline-schedules-callout');

  if (!el) {
    return;
  }

  const { docsUrl, illustrationUrl } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    provide: {
      docsUrl,
      illustrationUrl,
    },
    render(createElement) {
      return createElement(PipelineSchedulesCallout);
    },
  });
});
