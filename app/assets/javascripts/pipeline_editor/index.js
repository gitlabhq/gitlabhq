import Vue from 'vue';

import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import typeDefs from './graphql/typedefs.graphql';
import { resolvers } from './graphql/resolvers';

import PipelineEditorApp from './pipeline_editor_app.vue';

export const initPipelineEditor = (selector = '#js-pipeline-editor') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const { ciConfigPath, commitId, defaultBranch, newMergeRequestPath, projectPath } = el?.dataset;

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(resolvers, { typeDefs }),
  });

  return new Vue({
    el,
    apolloProvider,
    render(h) {
      return h(PipelineEditorApp, {
        props: {
          ciConfigPath,
          commitId,
          defaultBranch,
          newMergeRequestPath,
          projectPath,
        },
      });
    },
  });
};
