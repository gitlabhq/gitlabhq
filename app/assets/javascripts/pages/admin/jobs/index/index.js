import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Translate from '~/vue_shared/translate';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import AdminJobsTableApp from '~/ci/admin/jobs_table/admin_jobs_table_app.vue';
import cacheConfig from '~/ci/admin/jobs_table/graphql/cache_config';

Vue.use(Translate);
Vue.use(VueApollo);

const client = createDefaultClient({}, { cacheConfig });

const apolloProvider = new VueApollo({
  defaultClient: client,
});

const initAdminJobsApp = () => {
  const containerEl = document.getElementById('admin-jobs-app');

  if (!containerEl) return false;

  const { jobStatuses, emptyStateSvgPath, url, canUpdateAllJobs } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    apolloProvider,
    provide: {
      url,
      emptyStateSvgPath,
      jobStatuses: JSON.parse(jobStatuses),
      canUpdateAllJobs: parseBoolean(canUpdateAllJobs),
    },
    render(createElement) {
      return createElement(AdminJobsTableApp);
    },
  });
};

initAdminJobsApp();
