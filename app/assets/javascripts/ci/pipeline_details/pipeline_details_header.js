import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { parseBoolean } from '~/lib/utils/common_utils';
import PipelineDetailsHeader from './header/pipeline_details_header.vue';

Vue.use(VueApollo);

export const createPipelineDetailsHeaderApp = (elSelector, apolloProvider, graphqlResourceEtag) => {
  const el = document.querySelector(elSelector);

  if (!el) {
    return;
  }

  const { fullPath, pipelineIid, pipelinesPath, yamlErrors, trigger } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'PipelineDetailsHeaderApp',
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
      return createElement(PipelineDetailsHeader, {
        props: {
          yamlErrors,
          trigger: parseBoolean(trigger),
        },
      });
    },
  });
};
