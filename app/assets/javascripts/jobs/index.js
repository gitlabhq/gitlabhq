import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import JobApp from './components/job_app.vue';
import createStore from './store';

Vue.use(GlToast);

const initializeJobPage = (element) => {
  const store = createStore();

  // Let's start initializing the store (i.e. fetching data) right away
  store.dispatch('init', element.dataset);

  const {
    artifactHelpUrl,
    deploymentHelpUrl,
    runnerSettingsUrl,
    subscriptionsMoreMinutesUrl,
    endpoint,
    pagePath,
    logState,
    buildStatus,
    projectPath,
    retryOutdatedJobDocsUrl,
  } = element.dataset;

  return new Vue({
    el: element,
    store,
    components: {
      JobApp,
    },
    provide: {
      retryOutdatedJobDocsUrl,
    },
    render(createElement) {
      return createElement('job-app', {
        props: {
          artifactHelpUrl,
          deploymentHelpUrl,
          runnerSettingsUrl,
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

export default () => {
  const jobElement = document.getElementById('js-job-page');
  initializeJobPage(jobElement);
};
