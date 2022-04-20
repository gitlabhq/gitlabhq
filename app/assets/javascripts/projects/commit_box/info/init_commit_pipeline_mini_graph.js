import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient({}, { useGet: true }),
});

export const initCommitPipelineMiniGraph = async (selector = '.js-commit-pipeline-mini-graph') => {
  const el = document.querySelector(selector);

  if (!el) {
    return;
  }

  const { stages, fullPath, iid, graphqlResourceEtag } = el.dataset;

  // Some commits have no pipeline, code splitting to load the pipeline optionally
  const { default: CommitBoxPipelineMiniGraph } = await import(
    /* webpackChunkName: 'commitBoxPipelineMiniGraph' */ './components/commit_box_pipeline_mini_graph.vue'
  );

  // eslint-disable-next-line no-new
  new Vue({
    el,
    apolloProvider,
    provide: {
      fullPath,
      iid,
      dataMethod: 'graphql',
      graphqlResourceEtag,
    },
    render(createElement) {
      return createElement(CommitBoxPipelineMiniGraph, {
        props: {
          // if stages do not exist for some reason, protect JSON.parse from erroring out
          stages: stages ? JSON.parse(stages) : [],
        },
      });
    },
  });
};
