import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Translate from '~/vue_shared/translate';
import createDefaultClient from '~/lib/graphql';
import AdminJobsTableApp from '../components/table/admin_jobs_table_app.vue';
import cacheConfig from '../components/table/graphql/cache_config';

Vue.use(Translate);
Vue.use(VueApollo);

const client = createDefaultClient({}, { cacheConfig });

const apolloProvider = new VueApollo({
  defaultClient: client,
});

const initAdminJobsApp = () => {
  const containerEl = document.getElementById('admin-jobs-app');

  if (!containerEl) return false;

  const { jobStatuses, emptyStateSvgPath, url } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    apolloProvider,
    provide: {
      url,
      emptyStateSvgPath,
      jobStatuses: JSON.parse(jobStatuses),
    },
    render(createElement) {
      return createElement(AdminJobsTableApp);
    },
  });
};

initAdminJobsApp();
