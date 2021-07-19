import Vue from 'vue';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import Translate from '~/vue_shared/translate';
import stopJobsModal from './components/stop_jobs_modal.vue';

Vue.use(Translate);

function initJobs() {
  const buttonId = 'js-stop-jobs-button';
  const modalId = 'stop-jobs-modal';
  const stopJobsButton = document.getElementById(buttonId);
  if (stopJobsButton) {
    // eslint-disable-next-line no-new
    new Vue({
      el: `#js-${modalId}`,
      components: {
        stopJobsModal,
      },
      mounted() {
        stopJobsButton.classList.remove('disabled');
        stopJobsButton.addEventListener('click', () => {
          this.$root.$emit(BV_SHOW_MODAL, modalId, `#${buttonId}`);
        });
      },
      render(createElement) {
        return createElement(modalId, {
          props: {
            url: stopJobsButton.dataset.url,
          },
        });
      },
    });
  }
}

initJobs();
