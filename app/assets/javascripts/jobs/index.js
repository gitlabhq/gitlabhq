import Vue from 'vue';
import JobApp from './components/job_app.vue';

/**
 * Entry point for the job page app
 */

export default () => {
  const el = document.getElementById('js-vue-job-app');

  return new Vue({
    el,
    components: {
      JobApp,
    },
    render(createElement) {
      return createElement('job-app', {
        props: {
          jobEndpoint: el.dataset.jobEndpoint,
          traceOptions: {
            buildStage: el.dataset.traceOptionsBuildStage,
            buildStatus: el.dataset.traceOptionsBuildStatus,
            logState: el.dataset.traceOptionsLogState,
            pagePath: el.dataset.traceOptionsPagePath,
          },
          runnerHelpUrl: el.dataset.runnerHelpUrl,
          terminalPath: el.dataset.terminalPath,
          runnersPath: el.dataset.runnersPath,
        },
      });
    },
  });
};
