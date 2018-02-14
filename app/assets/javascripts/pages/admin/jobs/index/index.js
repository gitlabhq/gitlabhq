import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import mountComponent from '~/vue_shared/mount_vue_component';
import StopJobsModal from './components/stop_jobs_modal.vue';

Vue.use(Translate);

export default () => {
  const stopJobsButton = document.getElementById('stop-jobs-button');

  if (stopJobsButton) {
    stopJobsButton.classList.add('disabled');

    const modal = mountComponent(StopJobsModal, '#stop-jobs-modal');

    modal.$on('mounted', () => {
      stopJobsButton.classList.remove('disabled');
    });
  }
};
