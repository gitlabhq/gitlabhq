import Vue from 'vue';
import JobApp from './components/job_app.vue';

export default () => {
  const element = document.getElementById('js-job-vue-app');

  return new Vue({
    el: element,
    components: {
      JobApp,
    },
    render(createElement) {
      return createElement('job-app', {
        props: {
          deploymentHelpUrl: element.dataset.deploymentHelpUrl,
          runnerHelpUrl: element.dataset.runnerHelpUrl,
          runnerSettingsUrl: element.dataset.runnerSettingsUrl,
          variablesSettingsUrl: element.dataset.variablesSettingsUrl,
          endpoint: element.dataset.endpoint,
          pagePath: element.dataset.buildOptionsPagePath,
          logState: element.dataset.buildOptionsLogState,
          buildStatus: element.dataset.buildOptionsBuildStatus,
        },
      });
    },
  });
};
