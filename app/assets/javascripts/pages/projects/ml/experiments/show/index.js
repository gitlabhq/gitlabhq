import Vue from 'vue';
import MlExperimentsShow from '~/ml/experiment_tracking/routes/experiments/show/ml_experiments_show.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

const initShowExperiment = () => {
  const element = document.querySelector('#js-show-ml-experiment');
  if (!element) {
    return undefined;
  }

  const props = {
    candidates: JSON.parse(element.dataset.candidates),
    metricNames: JSON.parse(element.dataset.metrics),
    paramNames: JSON.parse(element.dataset.params),
    pageInfo: convertObjectPropsToCamelCase(JSON.parse(element.dataset.pageInfo)),
  };

  return new Vue({
    el: element,
    render(h) {
      return h(MlExperimentsShow, { props });
    },
  });
};

initShowExperiment();
