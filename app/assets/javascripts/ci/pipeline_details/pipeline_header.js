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
    mergeTrainsAvailable,
    canReadMergeTrain,
    mergeTrainsPath,
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
      mergeTrainsAvailable: parseBoolean(mergeTrainsAvailable),
      canReadMergeTrain: parseBoolean(canReadMergeTrain),
      mergeTrainsPath,
    },
    render(createElement) {
      return createElement(PipelineHeader);
    },
  });
};
