import Vue from 'vue';
import JobApp from './components/job_app.vue';

export default () => {
  const datasetJob = document.getElementById('js-vue-job-app').dataset;

  return new Vue({
    el: '#js-vue-job-app',
    components: {
      JobApp,
    },
    render(createElement) {
      return createElement('job-app', {
        props: {
          jobEndpoint: datasetJob.jobEndpoint,
          traceOptions: {
            buildStage: datasetJob.traceOptionsBuildStage,
            buildStatus: datasetJob.traceOptionsBuildStatus,
            logState: datasetJob.traceOptionsLogState,
            pagePath: datasetJob.traceOptionsPagePath,
          },
          runnerHelpUrl: datasetJob.runnerHelpUrl,
          terminalPath: datasetJob.terminalPath,
        },
      });
    },
  });
};
