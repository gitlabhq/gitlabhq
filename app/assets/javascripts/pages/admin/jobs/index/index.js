import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import stopJobsModal from './components/stop_jobs_modal.vue';

Vue.use(Translate);

document.addEventListener('DOMContentLoaded', () => {
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
          this.$root.$emit('bv::show::modal', modalId, `#${buttonId}`);
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
});
