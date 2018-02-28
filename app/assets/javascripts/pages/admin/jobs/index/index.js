import Vue from 'vue';

import Translate from '~/vue_shared/translate';

import stopJobsModal from './components/stop_jobs_modal.vue';

Vue.use(Translate);

export default () => {
  const stopJobsButton = document.getElementById('stop-jobs-button');

  // eslint-disable-next-line no-new
  new Vue({
    el: '#stop-jobs-modal',
    components: {
      stopJobsModal,
    },
    mounted() {
      stopJobsButton.classList.remove('disabled');
    },
    render(createElement) {
      return createElement('stop-jobs-modal', {
        props: {
          url: stopJobsButton.dataset.url,
        },
      });
    },
  });
};
