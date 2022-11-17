import Vue from 'vue';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import Translate from '~/vue_shared/translate';
import { STOP_JOBS_MODAL_ID } from './components/constants';
import StopJobsModal from './components/stop_jobs_modal.vue';

Vue.use(Translate);

function initJobs() {
  const buttonId = 'js-stop-jobs-button';
  const stopJobsButton = document.getElementById(buttonId);
  if (stopJobsButton) {
    // eslint-disable-next-line no-new
    new Vue({
      el: `#js-${STOP_JOBS_MODAL_ID}`,
      components: {
        StopJobsModal,
      },
      mounted() {
        stopJobsButton.classList.remove('disabled');
        stopJobsButton.addEventListener('click', () => {
          this.$root.$emit(BV_SHOW_MODAL, STOP_JOBS_MODAL_ID, `#${buttonId}`);
        });
      },
      render(createElement) {
        return createElement(STOP_JOBS_MODAL_ID, {
          props: {
            url: stopJobsButton.dataset.url,
          },
        });
      },
    });
  }
}

initJobs();
