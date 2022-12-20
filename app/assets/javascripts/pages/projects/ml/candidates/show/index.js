import Vue from 'vue';
import MlCandidate from '~/ml/experiment_tracking/components/ml_candidate.vue';

const initShowCandidate = () => {
  const element = document.querySelector('#js-show-ml-candidate');
  if (!element) {
    return;
  }

  const container = document.createElement('div');
  element.appendChild(container);

  const candidate = JSON.parse(element.dataset.candidate);

  // eslint-disable-next-line no-new
  new Vue({
    el: container,
    provide: {
      candidate,
    },
    render(h) {
      return h(MlCandidate);
    },
  });
};

initShowCandidate();
