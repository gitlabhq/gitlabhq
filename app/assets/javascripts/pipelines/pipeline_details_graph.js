import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import PipelineGraphWrapper from './components/graph/graph_component_wrapper.vue';
import { GRAPHQL } from './components/graph/constants';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
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
    render(createElement) {
      return createElement(PipelineGraphWrapper);
    },
  });
};

export { createPipelinesDetailApp };
