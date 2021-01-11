import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import PipelineGraphWrapper from './components/graph/graph_component_wrapper.vue';
import { GRAPHQL } from './components/graph/constants';
import { reportToSentry } from './components/graph/utils';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(
    {},
    {
      batchMax: 2,
    },
  ),
});

const createPipelinesDetailApp = (selector, pipelineProjectPath, pipelineIid) => {
  // eslint-disable-next-line no-new
  new Vue({
    el: selector,
    components: {
      PipelineGraphWrapper,
    },
    apolloProvider,
    provide: {
      pipelineProjectPath,
      pipelineIid,
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
