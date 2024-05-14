import Vue from 'vue';
import VueApollo from 'vue-apollo';
import PipelineHeader from './header/pipeline_header.vue';

Vue.use(VueApollo);

export const createPipelineHeaderApp = (elSelector, apolloProvider, graphqlResourceEtag) => {
  const el = document.querySelector(elSelector);

  if (!el) {
    return;
  }

  const { fullPath, pipelineIid, pipelinesPath } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'PipelineHeaderApp',
    apolloProvider,
    provide: {
      paths: {
        fullProject: fullPath,
        graphqlResourceEtag,
        pipelinesPath,
      },
      pipelineIid,
    },
    render(createElement) {
      return createElement(PipelineHeader);
    },
  });
};
