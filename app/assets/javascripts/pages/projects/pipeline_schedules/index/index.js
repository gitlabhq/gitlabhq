import Vue from 'vue';
import PipelineSchedulesCallout from '../shared/components/pipeline_schedules_callout.vue';

document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '#pipeline-schedules-callout',
  components: {
    'pipeline-schedules-callout': PipelineSchedulesCallout,
  },
  render(createElement) {
    return createElement('pipeline-schedules-callout');
  },
}));
