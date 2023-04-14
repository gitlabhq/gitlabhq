import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import Translate from '~/vue_shared/translate';
import createDefaultClient from '~/lib/graphql';
import { CANCEL_JOBS_MODAL_ID } from '../components/constants';
import CancelJobsModal from '../components/cancel_jobs_modal.vue';
import AdminJobsTableApp from '../components/table/admin_jobs_table_app.vue';
import cacheConfig from '../components/table/graphql/cache_config';

Vue.use(Translate);
Vue.use(VueApollo);

const client = createDefaultClient({}, { cacheConfig });

const apolloProvider = new VueApollo({
  defaultClient: client,
});

function initJobs() {
  const buttonId = 'js-stop-jobs-button';
  const cancelJobsButton = document.getElementById(buttonId);
  if (cancelJobsButton) {
    // eslint-disable-next-line no-new
    new Vue({
      el: `#js-${CANCEL_JOBS_MODAL_ID}`,
      components: {
        CancelJobsModal,
      },
      mounted() {
        cancelJobsButton.classList.remove('disabled');
        cancelJobsButton.addEventListener('click', () => {
          this.$root.$emit(BV_SHOW_MODAL, CANCEL_JOBS_MODAL_ID, `#${buttonId}`);
        });
      },
      render(createElement) {
        return createElement(CANCEL_JOBS_MODAL_ID, {
          props: {
            url: cancelJobsButton.dataset.url,
            modalId: CANCEL_JOBS_MODAL_ID,
          },
        });
      },
    });
  }
}

export function initAdminJobsApp() {
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
}

if (gon.features.adminJobsVue) {
  initAdminJobsApp();
} else {
  initJobs();
}
