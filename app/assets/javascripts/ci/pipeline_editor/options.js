import Vue from 'vue';

import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import PipelineEditorApp from 'jh_else_ce/ci/pipeline_editor/pipeline_editor_app.vue';
import { EDITOR_APP_STATUS_LOADING } from './constants';
import { CODE_SNIPPET_SOURCE_SETTINGS } from './components/code_snippet_alert/constants';
import getCurrentBranch from './graphql/queries/client/current_branch.query.graphql';
import getAppStatus from './graphql/queries/client/app_status.query.graphql';
import getLastCommitBranch from './graphql/queries/client/last_commit_branch.query.graphql';
import getPipelineEtag from './graphql/queries/client/pipeline_etag.query.graphql';
import { resolvers } from './graphql/resolvers';
import typeDefs from './graphql/typedefs.graphql';

export const createAppOptions = (el) => {
  const {
    // Add to apollo cache as it can be updated by future queries
    initialBranchName,
    pipelineEtag,
    // Add to provide/inject API for static values
    ciCatalogPath,
    ciConfigPath,
    ciExamplesHelpPagePath,
    ciHelpPagePath,
    ciLintPath,
    ciTroubleshootingPath,
    defaultBranch,
    emptyStateIllustrationPath,
    helpPaths,
    includesHelpPagePath,
    lintHelpPagePath,
    needsHelpPagePath,
    newMergeRequestPath,
    pipelinePagePath,
    projectFullPath,
    projectPath,
    projectNamespace,
    simulatePipelineHelpPagePath,
    totalBranches,
    usesExternalConfig,
    validateTabIllustrationPath,
    ymlHelpPagePath,
  } = el.dataset;

  const configurationPaths = Object.fromEntries(
    Object.entries(CODE_SNIPPET_SOURCE_SETTINGS).map(([source, { datasetKey }]) => [
      source,
      el.dataset[datasetKey],
    ]),
  );

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(resolvers, {
      typeDefs,
    }),
  });
  const { cache } = apolloProvider.clients.defaultClient;

  cache.writeQuery({
    query: getAppStatus,
    data: {
      app: {
        __typename: 'PipelineEditorApp',
        status: EDITOR_APP_STATUS_LOADING,
      },
    },
  });

  cache.writeQuery({
    query: getCurrentBranch,
    data: {
      workBranches: {
        __typename: 'BranchList',
        current: {
          __typename: 'WorkBranch',
          name: initialBranchName || defaultBranch,
        },
      },
    },
  });

  cache.writeQuery({
    query: getLastCommitBranch,
    data: {
      workBranches: {
        __typename: 'BranchList',
        lastCommit: {
          __typename: 'WorkBranch',
          name: '',
        },
      },
    },
  });

  cache.writeQuery({
    query: getPipelineEtag,
    data: {
      etags: {
        __typename: 'EtagValues',
        pipeline: pipelineEtag,
      },
    },
  });

  return {
    el,
    apolloProvider,
    provide: {
      ciCatalogPath,
      ciConfigPath,
      ciExamplesHelpPagePath,
      ciHelpPagePath,
      ciLintPath,
      ciTroubleshootingPath,
      configurationPaths,
      dataMethod: 'graphql',
      defaultBranch,
      emptyStateIllustrationPath,
      helpPaths,
      includesHelpPagePath,
      lintHelpPagePath,
      needsHelpPagePath,
      newMergeRequestPath,
      pipelinePagePath,
      projectFullPath,
      projectPath,
      projectNamespace,
      simulatePipelineHelpPagePath,
      totalBranches: parseInt(totalBranches, 10),
      usesExternalConfig: parseBoolean(usesExternalConfig),
      validateTabIllustrationPath,
      ymlHelpPagePath,
    },
    render(h) {
      return h(PipelineEditorApp);
    },
  };
};
