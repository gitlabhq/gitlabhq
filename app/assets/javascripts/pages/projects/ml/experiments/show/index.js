import Vue from 'vue';
import ShowExperiment from '~/ml/experiment_tracking/components/experiment.vue';

const initShowExperiment = () => {
  const element = document.querySelector('#js-show-ml-experiment');
  if (!element) {
    return;
  }

  const container = document.createElement('div');
  element.appendChild(container);

  const candidates = JSON.parse(element.dataset.candidates);
  const metricNames = JSON.parse(element.dataset.metrics);
  const paramNames = JSON.parse(element.dataset.params);

  // eslint-disable-next-line no-new
  new Vue({
    el: container,
    provide: {
      candidates,
      metricNames,
      paramNames,
    },
    render(h) {
      return h(ShowExperiment);
    },
  });
};

initShowExperiment();
