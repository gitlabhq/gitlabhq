import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import JobsTableApp from '~/ci/jobs_page/jobs_page_app.vue';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initJobsPage = (containerId = 'js-jobs-table') => {
  const containerEl = document.getElementById(containerId);

  if (!containerEl) {
    return false;
  }

  const { fullPath, jobStatuses, pipelineEditorPath, admin, projectId } = containerEl.dataset;

  return initVueApp({
    el: containerEl,
    name: 'JobsTableAppRoot',
    apolloProvider,
    provide: {
      fullPath,
      pipelineEditorPath,
      jobStatuses: JSON.parse(jobStatuses),
      admin: parseBoolean(admin),
      projectId,
    },
    component: JobsTableApp,
  });
};
