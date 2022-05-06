import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import FailedJobsApp from './components/jobs/failed_jobs_app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const createPipelineFailedJobsApp = (selector) => {
  const containerEl = document.querySelector(selector);

  if (!containerEl) {
    return false;
  }

  const { fullPath, pipelineIid, failedJobsSummaryData } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    apolloProvider,
    provide: {
      fullPath,
      pipelineIid,
    },
    render(createElement) {
      return createElement(FailedJobsApp, {
        props: {
          failedJobsSummary: JSON.parse(failedJobsSummaryData),
        },
      });
    },
  });
};
