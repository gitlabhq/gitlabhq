import Vue from 'vue';
import MlExperimentsShow from '~/ml/experiment_tracking/routes/experiments/show/ml_experiments_show.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

const initShowExperiment = () => {
  const element = document.querySelector('#js-show-ml-experiment');
  if (!element) {
    return undefined;
  }

  const { experiment, candidates, metrics, params, pageInfo, emptyStateSvgPath } = element.dataset;

  const props = {
    experiment: JSON.parse(experiment),
    candidates: JSON.parse(candidates),
    metricNames: JSON.parse(metrics),
    paramNames: JSON.parse(params),
    pageInfo: convertObjectPropsToCamelCase(JSON.parse(pageInfo)),
    emptyStateSvgPath,
  };

  return new Vue({
    el: element,
    render(h) {
      return h(MlExperimentsShow, { props });
    },
  });
};

initShowExperiment();
