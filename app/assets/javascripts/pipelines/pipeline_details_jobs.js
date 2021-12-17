import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import JobsApp from './components/jobs/jobs_app.vue';

Vue.use(VueApollo);
Vue.use(GlToast);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const createPipelineJobsApp = (selector) => {
  const containerEl = document.querySelector(selector);

  if (!containerEl) {
    return false;
  }

  const { fullPath, pipelineIid } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    apolloProvider,
    provide: {
      fullPath,
      pipelineIid,
    },
    render(createElement) {
      return createElement(JobsApp);
    },
  });
};
