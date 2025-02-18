// Fixtures located in spec/frontend/fixtures/job_artifacts.rb
import getJobArtifactsResponse from 'test_fixtures/graphql/ci/artifacts/graphql/queries/get_job_artifacts.query.graphql.json';

export const jobArtifactsResponseWithSecurityFiles = {
  data: {
    ...getJobArtifactsResponse.data,
    project: {
      ...getJobArtifactsResponse.data.project,
      jobs: {
        nodes: [
          {
            ...getJobArtifactsResponse.data.project.jobs.nodes[0],
            artifacts: {
              nodes: [
                {
                  id: 'gid://gitlab/Ci::JobArtifact/9539',
                  name: 'job.log',
                  fileType: 'TRACE',
                  downloadPath:
                    '/root/security-reports/-/jobs/12281/artifacts/download?file_type=trace',
                  size: '1842',
                  expireAt: null,
                },
                {
                  id: 'gid://gitlab/Ci::JobArtifact/9500',
                  name: 'gl-sast-report.json',
                  fileType: 'SAST',
                  downloadPath:
                    '/root/security-reports/-/jobs/12281/artifacts/download?file_type=sast',
                  size: '2036',
                  expireAt: '2025-02-08T17:00:46Z',
                },
              ],
            },
          },
        ],
        pageInfo: { ...getJobArtifactsResponse.data.project.jobs.pageInfo },
      },
    },
  },
};
