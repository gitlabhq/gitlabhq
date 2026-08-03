import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import JobApp from './job_app.vue';
import createStore from './store';

Vue.use(VueApollo);
Vue.use(GlToast);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initJobDetails = () => {
  const el = document.getElementById('js-job-page');
  if (!el) {
    return null;
  }

  const {
    jobEndpoint,
    logEndpoint,
    pagePath,
    projectPath,
    artifactHelpUrl,
    deploymentHelpUrl,
    runnerSettingsUrl,
    retryOutdatedJobDocsUrl,
    testReportSummaryUrl,
    pipelineTestReportUrl,
    logViewerPath,
    canSetPipelineVariables,
  } = el.dataset;

  const fullScreenAPIAvailable = document.fullscreenEnabled;

  // init store to start fetching log
  const store = createStore();
  store.dispatch('init', {
    jobEndpoint,
    logEndpoint,
    testReportSummaryUrl,
    fullScreenAPIAvailable,
  });

  return initVueApp({
    el,
    name: 'JobAppRoot',
    apolloProvider,
    store,
    provide: {
      pagePath,
      projectPath,
      retryOutdatedJobDocsUrl,
      pipelineTestReportUrl,
      canSetPipelineVariables: parseBoolean(canSetPipelineVariables),
    },
    component: JobApp,
    props: {
      artifactHelpUrl,
      deploymentHelpUrl,
      runnerSettingsUrl,
      logViewerPath,
    },
  });
};
