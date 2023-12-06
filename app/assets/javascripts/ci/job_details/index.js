import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
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
    artifactHelpUrl,
    deploymentHelpUrl,
    runnerSettingsUrl,
    subscriptionsMoreMinutesUrl,
    endpoint,
    pagePath,
    projectPath,
    retryOutdatedJobDocsUrl,
    aiRootCauseAnalysisAvailable,
    testReportSummaryUrl,
    pipelineTestReportUrl,
  } = el.dataset;

  // init store to start fetching log
  const store = createStore();
  store.dispatch('init', { endpoint, pagePath, testReportSummaryUrl });

  return new Vue({
    el,
    apolloProvider,
    store,
    provide: {
      projectPath,
      retryOutdatedJobDocsUrl,
      aiRootCauseAnalysisAvailable: parseBoolean(aiRootCauseAnalysisAvailable),
      pipelineTestReportUrl,
    },
    render(h) {
      return h(JobApp, {
        props: {
          artifactHelpUrl,
          deploymentHelpUrl,
          runnerSettingsUrl,
          subscriptionsMoreMinutesUrl,
        },
      });
    },
  });
};
