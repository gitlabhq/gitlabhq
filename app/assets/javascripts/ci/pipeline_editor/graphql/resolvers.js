import axios from '~/lib/utils/axios_utils';
import getAppStatus from './queries/client/app_status.query.graphql';
import getCurrentBranch from './queries/client/current_branch.query.graphql';
import getLastCommitBranch from './queries/client/last_commit_branch.query.graphql';
import getPipelineEtag from './queries/client/pipeline_etag.query.graphql';

export const resolvers = {
  Mutation: {
    lintCI: (_, { endpoint, content, dry_run }) => {
      return axios.post(endpoint, { content, dry_run }).then(({ data }) => {
        const { errors, warnings, valid, jobs } = data;

        return {
          valid,
          errors,
          warnings,
          jobs: jobs.map((job) => {
            const only = job.only
              ? { refs: job.only.refs, __typename: 'CiLintJobOnlyPolicy' }
              : null;

            return {
              name: job.name,
              stage: job.stage,
              beforeScript: job.before_script,
              script: job.script,
              afterScript: job.after_script,
              tags: job.tag_list,
              environment: job.environment,
              when: job.when,
              allowFailure: job.allow_failure,
              only,
              except: job.except,
              __typename: 'CiLintJob',
            };
          }),
          __typename: 'CiLintContent',
        };
      });
    },
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
