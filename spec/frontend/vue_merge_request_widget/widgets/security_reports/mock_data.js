export const mockArtifacts = () => ({
  data: {
    project: {
      id: 'gid://gitlab/Project/9',
      mergeRequest: {
        id: 'gid://gitlab/MergeRequest/1',
        headPipeline: {
          id: 'gid://gitlab/Ci::Pipeline/1',
          jobs: {
            nodes: [
              {
                id: 'gid://gitlab/Ci::Build/17',
                name: null,
                artifacts: {
                  nodes: [
                    {
                      downloadPath:
                        '/root/security-reports/-/jobs/17/artifacts/download?file_type=trace',
                      fileType: 'TRACE',
                      __typename: 'CiJobArtifact',
                    },
                    {
                      downloadPath:
                        '/root/security-reports/-/jobs/17/artifacts/download?file_type=sast',
                      fileType: 'SAST',
                      __typename: 'CiJobArtifact',
                    },
                  ],
                  __typename: 'CiJobArtifactConnection',
                },
                __typename: 'CiJob',
              },
              {
                id: 'gid://gitlab/Ci::Build/16',
                name: 'sam_scan',
                artifacts: {
                  nodes: [
                    {
                      downloadPath:
                        '/root/security-reports/-/jobs/16/artifacts/download?file_type=trace',
                      fileType: 'TRACE',
                      __typename: 'CiJobArtifact',
                    },
                    {
                      downloadPath:
                        '/root/security-reports/-/jobs/16/artifacts/download?file_type=sast',
                      fileType: null,
                      __typename: 'CiJobArtifact',
                    },
                  ],
                  __typename: 'CiJobArtifactConnection',
                },
                __typename: 'CiJob',
              },
              {
                id: 'gid://gitlab/Ci::Build/15',
                name: 'sast-spotbugs',
                artifacts: {
                  nodes: [
                    {
                      downloadPath:
                        '/root/security-reports/-/jobs/15/artifacts/download?file_type=trace',
                      fileType: 'TRACE',
                      __typename: 'CiJobArtifact',
                    },
                    {
                      downloadPath: null,
                      fileType: 'SAST',
                      __typename: 'CiJobArtifact',
                    },
                  ],
                  __typename: 'CiJobArtifactConnection',
                },
                __typename: 'CiJob',
              },
              {
                id: 'gid://gitlab/Ci::Build/14',
                name: 'sam_scan',
                artifacts: {
                  nodes: [
                    {
                      downloadPath:
                        '/root/security-reports/-/jobs/14/artifacts/download?file_type=trace',
                      fileType: 'TRACE',
                      __typename: 'CiJobArtifact',
                    },
                    {
                      downloadPath:
                        '/root/security-reports/-/jobs/14/artifacts/download?file_type=sast',
                      fileType: 'SAST',
                      __typename: 'CiJobArtifact',
                    },
                  ],
                  __typename: 'CiJobArtifactConnection',
                },
                __typename: 'CiJob',
              },
              {
                id: 'gid://gitlab/Ci::Build/11',
                name: 'sast-spotbugs',
                artifacts: {
                  nodes: [
                    {
                      downloadPath:
                        '/root/security-reports/-/jobs/11/artifacts/download?file_type=trace',
                      fileType: 'TRACE',
                      __typename: 'CiJobArtifact',
                    },
                    {
                      downloadPath:
                        '/root/security-reports/-/jobs/11/artifacts/download?file_type=sast',
                      fileType: 'SAST',
                      __typename: 'CiJobArtifact',
                    },
                  ],
                  __typename: 'CiJobArtifactConnection',
                },
                __typename: 'CiJob',
              },
              {
                id: 'gid://gitlab/Ci::Build/10',
                name: 'sast-sobelow',
                artifacts: {
                  nodes: [
                    {
                      downloadPath:
                        '/root/security-reports/-/jobs/10/artifacts/download?file_type=trace',
                      fileType: 'TRACE',
                      __typename: 'CiJobArtifact',
                    },
                  ],
                  __typename: 'CiJobArtifactConnection',
                },
                __typename: 'CiJob',
              },
              {
                id: 'gid://gitlab/Ci::Build/9',
                name: 'sast-pmd-apex',
                artifacts: {
                  nodes: [
                    {
                      downloadPath:
                        '/root/security-reports/-/jobs/9/artifacts/download?file_type=trace',
                      fileType: 'TRACE',
                      __typename: 'CiJobArtifact',
                    },
                  ],
                  __typename: 'CiJobArtifactConnection',
                },
                __typename: 'CiJob',
              },
              {
                id: 'gid://gitlab/Ci::Build/8',
                name: 'sast-eslint',
                artifacts: {
                  nodes: [
                    {
                      downloadPath:
                        '/root/security-reports/-/jobs/8/artifacts/download?file_type=trace',
                      fileType: 'TRACE',
                      __typename: 'CiJobArtifact',
                    },
                    {
                      downloadPath:
                        '/root/security-reports/-/jobs/8/artifacts/download?file_type=sast',
                      fileType: 'SAST',
                      __typename: 'CiJobArtifact',
                    },
                  ],
                  __typename: 'CiJobArtifactConnection',
                },
                __typename: 'CiJob',
              },
              {
                id: 'gid://gitlab/Ci::Build/7',
                name: 'secrets',
                artifacts: {
                  nodes: [
                    {
                      downloadPath:
                        '/root/security-reports/-/jobs/7/artifacts/download?file_type=trace',
                      fileType: 'TRACE',
                      __typename: 'CiJobArtifact',
                    },
                    {
                      downloadPath:
                        '/root/security-reports/-/jobs/7/artifacts/download?file_type=secret_detection',
                      fileType: 'SECRET_DETECTION',
                      __typename: 'CiJobArtifact',
                    },
                  ],
                  __typename: 'CiJobArtifactConnection',
                },
                __typename: 'CiJob',
              },
            ],
            __typename: 'CiJobConnection',
          },
          __typename: 'Pipeline',
        },
        __typename: 'MergeRequest',
      },
      __typename: 'Project',
    },
  },
});
