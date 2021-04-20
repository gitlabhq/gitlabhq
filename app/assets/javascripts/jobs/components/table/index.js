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

  const { fullPath, jobCounts, jobStatuses } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    apolloProvider,
    provide: {
      fullPath,
      jobStatuses: JSON.parse(jobStatuses),
      jobCounts: JSON.parse(jobCounts),
    },
    render(createElement) {
      return createElement(JobsTableApp);
    },
  });
};
