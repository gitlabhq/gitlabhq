import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import BridgeApp from './bridge/app.vue';
import JobApp from './components/job_app.vue';
import createStore from './store';

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

const initializeBridgePage = (el) => {
  const {
    buildId,
    downstreamPipelinePath,
    emptyStateIllustrationPath,
    pipelineIid,
    projectFullPath,
  } = el.dataset;

  Vue.use(VueApollo);
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    provide: {
      buildId,
      downstreamPipelinePath,
      emptyStateIllustrationPath,
      pipelineIid,
      projectFullPath,
    },
    render(h) {
      return h(BridgeApp);
    },
  });
};

export default () => {
  const jobElement = document.getElementById('js-job-page');
  const bridgeElement = document.getElementById('js-bridge-page');

  if (jobElement) {
    initializeJobPage(jobElement);
  } else {
    initializeBridgePage(bridgeElement);
  }
};
