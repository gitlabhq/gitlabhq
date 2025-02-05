import Vue from 'vue';
import MlExperimentsIndex from '~/ml/experiment_tracking/routes/experiments/index';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

const initIndexMlExperiments = () => {
  const element = document.querySelector('#js-project-ml-experiments-index');
  if (!element) {
    return undefined;
  }

  const { experiments, pageInfo, emptyStateSvgPath, mlflowTrackingUrl, count } = element.dataset;
  const props = {
    experiments: JSON.parse(experiments),
    pageInfo: convertObjectPropsToCamelCase(JSON.parse(pageInfo)),
    emptyStateSvgPath,
    mlflowTrackingUrl,
    count: parseInt(count, 10),
  };

  return new Vue({
    el: element,
    name: 'MlExperimentsIndexApp',
    render(h) {
      return h(MlExperimentsIndex, { props });
    },
  });
};

initIndexMlExperiments();
