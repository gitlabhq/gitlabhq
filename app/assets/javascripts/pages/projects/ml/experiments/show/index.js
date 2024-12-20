import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import MlExperimentsShow from '~/ml/experiment_tracking/routes/experiments/show/ml_experiments_show.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueRouter);

const initShowExperiment = () => {
  const element = document.querySelector('#js-show-ml-experiment');

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  if (!element) {
    return undefined;
  }

  const {
    experiment,
    candidates,
    metrics,
    params,
    pageInfo,
    emptyStateSvgPath,
    mlflowTrackingUrl,
  } = element.dataset;

  const props = {
    experiment: JSON.parse(experiment),
    candidates: JSON.parse(candidates),
    metricNames: JSON.parse(metrics),
    paramNames: JSON.parse(params),
    pageInfo: convertObjectPropsToCamelCase(JSON.parse(pageInfo)),
    emptyStateSvgPath,
    mlflowTrackingUrl,
  };

  return new Vue({
    el: element,
    apolloProvider,
    render(h) {
      return h(MlExperimentsShow, { props });
    },
  });
};

initShowExperiment();
