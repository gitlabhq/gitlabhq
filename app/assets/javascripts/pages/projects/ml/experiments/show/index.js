import Vue from 'vue';
import MlExperiment from '~/ml/experiment_tracking/components/ml_experiment.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

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
  const pagination = convertObjectPropsToCamelCase(JSON.parse(element.dataset.pagination));

  // eslint-disable-next-line no-new
  new Vue({
    el: container,
    provide: {
      candidates,
      metricNames,
      paramNames,
      pagination,
    },
    render(h) {
      return h(MlExperiment);
    },
  });
};

initShowExperiment();
