import getAppStatus from './queries/client/app_status.query.graphql';
import getCurrentBranch from './queries/client/current_branch.query.graphql';
import getLastCommitBranch from './queries/client/last_commit_branch.query.graphql';
import getPipelineEtag from './queries/client/pipeline_etag.query.graphql';

export const resolvers = {
  Mutation: {
    updateAppStatus: (_, { appStatus }, { cache }) => {
      cache.writeQuery({
        query: getAppStatus,
        data: {
          app: {
            __typename: 'PipelineEditorApp',
            status: appStatus,
          },
        },
      });
    },
    updateCurrentBranch: (_, { currentBranch }, { cache }) => {
      cache.writeQuery({
        query: getCurrentBranch,
        data: {
          workBranches: {
            __typename: 'BranchList',
            current: {
              __typename: 'WorkBranch',
              name: currentBranch,
            },
          },
        },
      });
    },
    updateLastCommitBranch: (_, { lastCommitBranch }, { cache }) => {
      cache.writeQuery({
        query: getLastCommitBranch,
        data: {
          workBranches: {
            __typename: 'BranchList',
            lastCommit: {
              __typename: 'WorkBranch',
              name: lastCommitBranch,
            },
          },
        },
      });
    },
    updatePipelineEtag: (_, { pipelineEtag }, { cache }) => {
      cache.writeQuery({
        query: getPipelineEtag,
        data: {
          etags: {
            __typename: 'EtagValues',
            pipeline: pipelineEtag,
          },
        },
      });
    },
  },
};
