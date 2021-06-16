import produce from 'immer';
import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import getCurrentBranchQuery from './queries/client/current_branch.graphql';
import getLastCommitBranchQuery from './queries/client/last_commit_branch.query.graphql';

export const resolvers = {
  Query: {
    blobContent(_, { projectPath, path, ref }) {
      return {
        __typename: 'BlobContent',
        rawData: Api.getRawFile(projectPath, path, { ref }).then(({ data }) => {
          return data;
        }),
      };
    },
  },
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
    updateCurrentBranch: (_, { currentBranch = undefined }, { cache }) => {
      cache.writeQuery({
        query: getCurrentBranchQuery,
        data: produce(cache.readQuery({ query: getCurrentBranchQuery }), (draftData) => {
          draftData.currentBranch = currentBranch;
        }),
      });
    },
    updateLastCommitBranch: (_, { lastCommitBranch = undefined }, { cache }) => {
      cache.writeQuery({
        query: getLastCommitBranchQuery,
        data: produce(cache.readQuery({ query: getLastCommitBranchQuery }), (draftData) => {
          draftData.lastCommitBranch = lastCommitBranch;
        }),
      });
    },
  },
};
