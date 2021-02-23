import Api from '~/api';
import axios from '~/lib/utils/axios_utils';

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

    /* eslint-disable @gitlab/require-i18n-strings */
    project() {
      return {
        __typename: 'Project',
        pipeline: {
          __typename: 'Pipeline',
          commitPath: `/-/commit/aabbccdd`,
          id: 'gid://gitlab/Ci::Pipeline/118',
          iid: '28',
          shortSha: 'aabbccdd',
          status: 'SUCCESS',
          detailedStatus: {
            __typename: 'DetailedStatus',
            detailsPath: '/root/sample-ci-project/-/pipelines/118"',
            group: 'success',
            icon: 'status_success',
            text: 'passed',
          },
        },
      };
    },
    /* eslint-enable @gitlab/require-i18n-strings */
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
  },
};
