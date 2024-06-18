import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { parseBoolean } from '~/lib/utils/common_utils';
import PipelineHeader from './header/pipeline_header.vue';

Vue.use(VueApollo);

export const createPipelineHeaderApp = (elSelector, apolloProvider, graphqlResourceEtag) => {
  const el = document.querySelector(elSelector);

  if (!el) {
    return;
  }

  const {
    fullPath,
    pipelineIid,
    pipelinesPath,
    identityVerificationPath,
    identityVerificationRequired,
  } = el.dataset;

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
      identityVerificationPath,
      identityVerificationRequired: parseBoolean(identityVerificationRequired),
    },
    render(createElement) {
      return createElement(PipelineHeader);
    },
  });
};
