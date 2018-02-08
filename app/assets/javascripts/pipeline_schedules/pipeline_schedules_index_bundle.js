import Vue from 'vue';
import PipelineSchedulesCallout from './components/pipeline_schedules_callout.vue';

document.addEventListener('DOMContentLoaded', () => Vue.create({
  el: '#pipeline-schedules-callout',
  components: {
    'pipeline-schedules-callout': PipelineSchedulesCallout,
  },
  render(createElement) {
    return createElement('pipeline-schedules-callout');
  },
}));
