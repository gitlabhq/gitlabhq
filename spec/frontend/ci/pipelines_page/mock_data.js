export const mockPipelinesData = {
  data: {
    project: {
      id: 'gid://gitlab/Project/19',
      pipelines: {
        nodes: [
          {
            id: 'gid://gitlab/Ci::Pipeline/701',
            iid: '63',
            detailedStatus: {
              id: 'success-701-701',
              icon: 'status_warning',
              text: 'Warning',
              detailsPath: '/root/ci-project/-/pipelines/701',
              __typename: 'DetailedStatus',
              name: 'SUCCESS_WITH_WARNINGS',
            },
            createdAt: '2025-09-25T16:23:33Z',
            finishedAt: '2025-09-25T16:24:02Z',
            duration: 17,
            name: 'Ruby 3.0 master branch pipeline',
            ref: 'main',
            refPath: 'refs/heads/main',
            refText:
              'For \u003ca class="ref-container gl-link" href="/root/ci-project/-/commits/main"\u003emain\u003c/a\u003e',
            commit: {
              id: 'gid://gitlab/Commit/ab708cdcfd838846528c736f36ac2d2fea4508fb',
              name: 'Update .gitlab-ci.yml file',
              sha: 'ab708cdcfd838846528c736f36ac2d2fea4508fb',
              shortId: 'ab708cdc',
              title: 'Update .gitlab-ci.yml file',
              webUrl:
                'http://gdk.test:3000/root/ci-project/-/commit/ab708cdcfd838846528c736f36ac2d2fea4508fb',
              author: {
                id: 'gid://gitlab/User/1',
                avatarUrl:
                  'https://www.gravatar.com/avatar/3699a2727a92a410332ca568fef4353e3ae40c0b0c1fd5043585ceec77dc0e05?s=80\u0026d=identicon',
                webPath: '/root',
                name: 'Administrator',
                __typename: 'UserCore',
              },
              __typename: 'Commit',
            },
            user: {
              id: 'gid://gitlab/User/1',
              name: 'Administrator',
              webPath: '/root',
              avatarUrl:
                'https://www.gravatar.com/avatar/3699a2727a92a410332ca568fef4353e3ae40c0b0c1fd5043585ceec77dc0e05?s=80\u0026d=identicon',
              __typename: 'UserCore',
            },
            source: 'schedule',
            latest: true,
            yamlErrors: false,
            failureReason: null,
            configSource: 'REPOSITORY_SOURCE',
            stuck: false,
            type: 'branch',
            path: '/root/ci-project/-/pipelines/701',
            retryable: true,
            cancelable: false,
            stages: {
              nodes: [
                {
                  id: 'gid://gitlab/Ci::Stage/429',
                  name: 'build',
                  detailedStatus: {
                    id: 'success-429-429',
                    icon: 'status_success',
                    text: 'Passed',
                    detailsPath: '/root/ci-project/-/pipelines/701#build',
                    __typename: 'DetailedStatus',
                    tooltip: 'passed',
                  },
                  __typename: 'CiStage',
                },
                {
                  id: 'gid://gitlab/Ci::Stage/431',
                  name: 'test',
                  detailedStatus: {
                    id: 'success-431-431',
                    icon: 'status_warning',
                    text: 'Warning',
                    detailsPath: '/root/ci-project/-/pipelines/701#test',
                    __typename: 'DetailedStatus',
                    tooltip: 'passed',
                  },
                  __typename: 'CiStage',
                },
                {
                  id: 'gid://gitlab/Ci::Stage/434',
                  name: 'deploy',
                  detailedStatus: {
                    id: 'success-434-434',
                    icon: 'status_success',
                    text: 'Passed',
                    detailsPath: '/root/ci-project/-/pipelines/701#deploy',
                    __typename: 'DetailedStatus',
                    tooltip: 'passed',
                  },
                  __typename: 'CiStage',
                },
              ],
              __typename: 'CiStageConnection',
            },
            mergeRequest: null,
            mergeRequestEventType: null,
            project: {
              id: 'gid://gitlab/Project/19',
              fullPath: 'root/ci-project',
              __typename: 'Project',
            },
            hasManualActions: false,
            hasScheduledActions: false,
            __typename: 'Pipeline',
          },
          {
            id: 'gid://gitlab/Ci::Pipeline/699',
            iid: '62',
            detailedStatus: {
              id: 'success-699-699',
              icon: 'status_warning',
              text: 'Warning',
              detailsPath: '/root/ci-project/-/pipelines/699',
              __typename: 'DetailedStatus',
              name: 'SUCCESS_WITH_WARNINGS',
            },
            createdAt: '2025-09-18T15:04:38Z',
            finishedAt: '2025-09-18T15:04:59Z',
            duration: 16,
            name: 'Ruby 3.0 master branch pipeline',
            ref: 'main',
            refPath: 'refs/heads/main',
            refText:
              'For \u003ca class="ref-container gl-link" href="/root/ci-project/-/commits/main"\u003emain\u003c/a\u003e',
            commit: {
              id: 'gid://gitlab/Commit/ab708cdcfd838846528c736f36ac2d2fea4508fb',
              name: 'Update .gitlab-ci.yml file',
              sha: 'ab708cdcfd838846528c736f36ac2d2fea4508fb',
              shortId: 'ab708cdc',
              title: 'Update .gitlab-ci.yml file',
              webUrl:
                'http://gdk.test:3000/root/ci-project/-/commit/ab708cdcfd838846528c736f36ac2d2fea4508fb',
              author: {
                id: 'gid://gitlab/User/1',
                avatarUrl:
                  'https://www.gravatar.com/avatar/3699a2727a92a410332ca568fef4353e3ae40c0b0c1fd5043585ceec77dc0e05?s=80\u0026d=identicon',
                webPath: '/root',
                name: 'Administrator',
                __typename: 'UserCore',
              },
              __typename: 'Commit',
            },
            user: {
              id: 'gid://gitlab/User/1',
              name: 'Administrator',
              webPath: '/root',
              avatarUrl:
                'https://www.gravatar.com/avatar/3699a2727a92a410332ca568fef4353e3ae40c0b0c1fd5043585ceec77dc0e05?s=80\u0026d=identicon',
              __typename: 'UserCore',
            },
            source: 'web',
            latest: true,
            yamlErrors: false,
            failureReason: null,
            configSource: 'REPOSITORY_SOURCE',
            stuck: false,
            type: 'branch',
            path: '/root/ci-project/-/pipelines/699',
            retryable: true,
            cancelable: false,
            stages: {
              nodes: [
                {
                  id: 'gid://gitlab/Ci::Stage/424',
                  name: 'build',
                  detailedStatus: {
                    id: 'success-424-424',
                    icon: 'status_success',
                    text: 'Passed',
                    detailsPath: '/root/ci-project/-/pipelines/699#build',
                    __typename: 'DetailedStatus',
                    tooltip: 'passed',
                  },
                  __typename: 'CiStage',
                },
                {
                  id: 'gid://gitlab/Ci::Stage/425',
                  name: 'test',
                  detailedStatus: {
                    id: 'success-425-425',
                    icon: 'status_warning',
                    text: 'Warning',
                    detailsPath: '/root/ci-project/-/pipelines/699#test',
                    __typename: 'DetailedStatus',
                    tooltip: 'passed',
                  },
                  __typename: 'CiStage',
                },
                {
                  id: 'gid://gitlab/Ci::Stage/426',
                  name: 'deploy',
                  detailedStatus: {
                    id: 'success-426-426',
                    icon: 'status_success',
                    text: 'Passed',
                    detailsPath: '/root/ci-project/-/pipelines/699#deploy',
                    __typename: 'DetailedStatus',
                    tooltip: 'passed',
                  },
                  __typename: 'CiStage',
                },
              ],
              __typename: 'CiStageConnection',
            },
            mergeRequest: null,
            mergeRequestEventType: null,
            project: {
              id: 'gid://gitlab/Project/19',
              fullPath: 'root/ci-project',
              __typename: 'Project',
            },
            hasManualActions: false,
            hasScheduledActions: false,
            __typename: 'Pipeline',
          },
        ],
        pageInfo: {
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: 'eyJpZCI6IjcwMSJ9',
          endCursor: 'eyJpZCI6IjY3NSJ9',
          __typename: 'PageInfo',
        },
        __typename: 'PipelineConnection',
      },
      __typename: 'Project',
    },
  },
};

export const mockPipelinesDataEmpty = {
  data: {
    project: {
      id: 'gid://gitlab/Project/19',
      pipelines: {
        nodes: [],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: null,
          endCursor: null,
          __typename: 'PageInfo',
        },
        __typename: 'PipelineConnection',
      },
      __typename: 'Project',
    },
  },
};

export const mockRunnerCacheClearPayload = {
  data: {
    runnerCacheClear: {
      errors: [],
      __typename: 'RunnerCacheClearPayload',
    },
  },
};

export const mockRunnerCacheClearPayloadWithError = {
  data: {
    runnerCacheClear: {
      errors: ['Something went wrong'],
      __typename: 'RunnerCacheClearPayload',
    },
  },
};

export const mockPipelinesCount = {
  data: {
    project: {
      id: 'gid://gitlab/Project/19',
      pipelines: {
        count: 2,
        __typename: 'PipelineConnection',
      },
      __typename: 'Project',
    },
  },
};

export const mockRetryPipelineMutationResponse = {
  data: {
    pipelineRetry: {
      __typename: 'PipelineRetryPayload',
      pipeline: {
        id: 'gid://gitlab/Ci::Pipeline/701',
      },
      errors: [],
    },
  },
};

export const mockRetryFailedPipelineMutationResponse = {
  data: {
    pipelineRetry: {
      __typename: 'PipelineRetryPayload',
      pipeline: {
        id: '',
      },
      errors: ['Something went wrong'],
    },
  },
};

export const mockCancelPipelineMutationResponse = {
  data: {
    pipelineCancel: {
      __typename: 'PipelineCancelPayload',
      errors: [],
    },
  },
};

export const mockPipelinesFilteredSearch = [
  {
    type: 'username',
    value: {
      data: 'root',
      operator: '=',
    },
    id: 'token-18',
  },
  {
    type: 'status',
    value: {
      data: 'success',
      operator: '=',
    },
    id: 'token-20',
  },
  {
    type: 'source',
    value: {
      data: 'schedule',
      operator: '=',
    },
    id: 'token-22',
  },
  {
    type: 'ref',
    value: {
      data: 'test',
      operator: '=',
    },
    id: 'token-24',
  },
];
