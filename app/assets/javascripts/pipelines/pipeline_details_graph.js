import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GRAPHQL } from './components/graph/constants';
import PipelineGraphWrapper from './components/graph/graph_component_wrapper.vue';
import { reportToSentry } from './utils';

Vue.use(VueApollo);

const createPipelinesDetailApp = (
  selector,
  apolloProvider,
  { pipelineProjectPath, pipelineIid, metricsPath, graphqlResourceEtag } = {},
) => {
  // eslint-disable-next-line no-new
  new Vue({
    el: selector,
    components: {
      PipelineGraphWrapper,
    },
    apolloProvider,
    provide: {
      metricsPath,
      pipelineProjectPath,
      pipelineIid,
      graphqlResourceEtag,
      dataMethod: GRAPHQL,
    },
    errorCaptured(err, _vm, info) {
      reportToSentry('pipeline_details_graph', `error: ${err}, info: ${info}`);
    },
    render(createElement) {
      return createElement(PipelineGraphWrapper);
    },
  });
};

export { createPipelinesDetailApp };
