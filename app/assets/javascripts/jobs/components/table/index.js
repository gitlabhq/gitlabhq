import Vue from 'vue';
import VueApollo from 'vue-apollo';
import JobsTableApp from '~/jobs/components/table/jobs_table_app.vue';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default (containerId = 'js-jobs-table') => {
  const containerEl = document.getElementById(containerId);

  if (!containerEl) {
    return false;
  }

  const {
    fullPath,
    jobCounts,
    jobStatuses,
    pipelineEditorPath,
    emptyStateSvgPath,
  } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    apolloProvider,
    provide: {
      emptyStateSvgPath,
      fullPath,
      pipelineEditorPath,
      jobStatuses: JSON.parse(jobStatuses),
      jobCounts: JSON.parse(jobCounts),
    },
    render(createElement) {
      return createElement(JobsTableApp);
    },
  });
};
