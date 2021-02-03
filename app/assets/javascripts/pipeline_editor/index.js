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

  const {
    // Add to apollo cache as it can be updated by future queries
    commitSha,
    // Add to provide/inject API for static values
    ciConfigPath,
    defaultBranch,
    lintHelpPagePath,
    newMergeRequestPath,
    projectFullPath,
    projectPath,
    projectNamespace,
    ymlHelpPagePath,
  } = el?.dataset;

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(resolvers, { typeDefs }),
  });

  apolloProvider.clients.defaultClient.cache.writeData({
    data: {
      commitSha,
    },
  });

  return new Vue({
    el,
    apolloProvider,
    provide: {
      ciConfigPath,
      defaultBranch,
      lintHelpPagePath,
      newMergeRequestPath,
      projectFullPath,
      projectPath,
      projectNamespace,
      ymlHelpPagePath,
    },
    render(h) {
      return h(PipelineEditorApp);
    },
  });
};
