import Vue from 'vue';
import initPipelineSchedulesApp from '~/ci/pipeline_schedules/mount_pipeline_schedules_app';
import PipelineSchedulesCallout from '../shared/components/pipeline_schedules_callout.vue';

function initPipelineSchedulesCallout() {
  const el = document.getElementById('pipeline-schedules-callout');

  if (!el) {
    return;
  }

  const { docsUrl, illustrationUrl } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'PipelineSchedulesCalloutRoot',
    provide: {
      docsUrl,
      illustrationUrl,
    },
    render(createElement) {
      return createElement(PipelineSchedulesCallout);
    },
  });
}

initPipelineSchedulesApp();
initPipelineSchedulesCallout();
