import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import MlExperimentsShow from './routes/experiments/show/ml_experiments_show.vue';

Vue.use(VueRouter);

export const initShowExperiment = () => {
  const el = document.querySelector('#js-show-ml-experiment');

  if (!el) {
    return null;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const {
    experiment,
    candidates,
    metrics,
    params,
    pageInfo,
    emptyStateSvgPath,
    mlflowTrackingUrl,
    canWriteModelExperiments,
  } = el.dataset;

  const props = {
    experiment: JSON.parse(experiment),
    candidates: JSON.parse(candidates),
    metricNames: JSON.parse(metrics),
    paramNames: JSON.parse(params),
    pageInfo: convertObjectPropsToCamelCase(JSON.parse(pageInfo)),
    emptyStateSvgPath,
    mlflowTrackingUrl,
    canWriteModelExperiments: Boolean(canWriteModelExperiments),
  };

  return new Vue({
    el,
    name: 'MlExperimentsShow',
    apolloProvider,
    render(h) {
      return h(MlExperimentsShow, { props });
    },
  });
};
