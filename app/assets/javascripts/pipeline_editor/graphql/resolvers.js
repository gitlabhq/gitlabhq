import produce from 'immer';
import axios from '~/lib/utils/axios_utils';
import getCommitShaQuery from './queries/client/commit_sha.graphql';
import getCurrentBranchQuery from './queries/client/current_branch.graphql';
import getLastCommitBranchQuery from './queries/client/last_commit_branch.query.graphql';

export const resolvers = {
  Mutation: {
    lintCI: (_, { endpoint, content, dry_run }) => {
      return axios.post(endpoint, { content, dry_run }).then(({ data }) => ({
        valid: data.valid,
        errors: data.errors,
        warnings: data.warnings,
        jobs: data.jobs.map((job) => {
          const only = job.only ? { refs: job.only.refs, __typename: 'CiLintJobOnlyPolicy' } : null;

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
      }));
    },
    updateCommitSha: (_, { commitSha }, { cache }) => {
      cache.writeQuery({
        query: getCommitShaQuery,
        data: produce(cache.readQuery({ query: getCommitShaQuery }), (draftData) => {
          draftData.commitSha = commitSha;
        }),
      });
    },
    updateCurrentBranch: (_, { currentBranch }, { cache }) => {
      cache.writeQuery({
        query: getCurrentBranchQuery,
        data: produce(cache.readQuery({ query: getCurrentBranchQuery }), (draftData) => {
          draftData.currentBranch = currentBranch;
        }),
      });
    },
    updateLastCommitBranch: (_, { lastCommitBranch }, { cache }) => {
      cache.writeQuery({
        query: getLastCommitBranchQuery,
        data: produce(cache.readQuery({ query: getLastCommitBranchQuery }), (draftData) => {
          draftData.lastCommitBranch = lastCommitBranch;
        }),
      });
    },
  },
};
