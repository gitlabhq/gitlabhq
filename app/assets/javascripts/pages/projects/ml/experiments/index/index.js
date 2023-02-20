import Vue from 'vue';
import MlExperimentsIndex from '~/ml/experiment_tracking/routes/experiments/index';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

const initIndexMlExperiments = () => {
  const element = document.querySelector('#js-project-ml-experiments-index');
  if (!element) {
    return undefined;
  }

  const props = {
    experiments: JSON.parse(element.dataset.experiments),
    pageInfo: convertObjectPropsToCamelCase(JSON.parse(element.dataset.pageInfo)),
  };

  return new Vue({
    el: element,
    render(h) {
      return h(MlExperimentsIndex, { props });
    },
  });
};

initIndexMlExperiments();
