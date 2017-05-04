import Vue from 'vue';
import PipelineSchedulesCallout from './components/pipeline_schedules_callout';

const PipelineSchedulesCalloutComponent = Vue.extend(PipelineSchedulesCallout);

document.addEventListener('DOMContentLoaded', () => {
  new PipelineSchedulesCalloutComponent()
    .$mount('#scheduling-pipelines-callout');
});
