import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import pipelineHeader from './components/header_component.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const createPipelineHeaderApp = elSelector => {
  const el = document.querySelector(elSelector);

  if (!el) {
    return;
  }

  const { cancelPath, deletePath, fullPath, pipelineId, pipelineIid, retryPath } = el?.dataset;
  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      pipelineHeader,
    },
    apolloProvider,
    provide: {
      paths: {
        cancel: cancelPath,
        delete: deletePath,
        fullProject: fullPath,
        retry: retryPath,
      },
      pipelineId,
      pipelineIid,
    },
    render(createElement) {
      return createElement('pipeline-header', {});
    },
  });
};
