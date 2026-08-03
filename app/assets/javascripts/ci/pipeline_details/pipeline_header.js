import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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
    mergeRequestPath,
  } = el.dataset;

  initVueApp({
    el,
    name: 'PipelineHeaderApp',
    apolloProvider,
    provide: {
      paths: {
        fullProject: fullPath,
        graphqlResourceEtag,
        pipelinesPath,
        mergeRequestPath: mergeRequestPath ? `${gon.gitlab_url}${mergeRequestPath}` : '',
      },
      pipelineIid,
      identityVerificationPath,
      identityVerificationRequired: parseBoolean(identityVerificationRequired),
      mergeTrainsAvailable: parseBoolean(mergeTrainsAvailable),
      canReadMergeTrain: parseBoolean(canReadMergeTrain),
      mergeTrainsPath,
    },
    component: PipelineHeader,
  });
};
