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
      const {
        deploymentHelpUrl,
        runnerHelpUrl,
        runnerSettingsUrl,
        variablesSettingsUrl,
        subscriptionsMoreMinutesUrl,
        endpoint,
        pagePath,
        logState,
        buildStatus,
        projectPath,
      } = element.dataset;

      return createElement('job-app', {
        props: {
          deploymentHelpUrl,
          runnerHelpUrl,
          runnerSettingsUrl,
          variablesSettingsUrl,
          subscriptionsMoreMinutesUrl,
          endpoint,
          pagePath,
          logState,
          buildStatus,
          projectPath,
        },
      });
    },
  });
};
