import Vue from 'vue';
import VueApollo from 'vue-apollo';
import pipelineHeader from './components/header_component.vue';

Vue.use(VueApollo);

export const createPipelineHeaderApp = (elSelector, apolloProvider, graphqlResourceEtag) => {
  const el = document.querySelector(elSelector);

  if (!el) {
    return;
  }

  const { fullPath, pipelineId, pipelineIid, pipelinesPath } = el?.dataset;
  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      pipelineHeader,
    },
    apolloProvider,
    provide: {
      paths: {
        fullProject: fullPath,
        graphqlResourceEtag,
        pipelinesPath,
      },
      pipelineId,
      pipelineIid,
    },
    render(createElement) {
      return createElement('pipeline-header', {});
    },
  });
};
