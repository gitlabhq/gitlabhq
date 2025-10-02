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
            },
            createdAt: '2025-09-25T16:23:33Z',
            finishedAt: '2025-09-25T16:24:02Z',
            duration: 17,
            name: 'Ruby 3.0 master branch pipeline',
            ref: 'main',
            refPath: 'refs/heads/main',
            refText:
              'For <a class="ref-container gl-link" href="/root/ci-project/-/commits/main">main</a>',
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
                  'https://www.gravatar.com/avatar/3699a2727a92a410332ca568fef4353e3ae40c0b0c1fd5043585ceec77dc0e05?s=80&d=identicon',
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
                'https://www.gravatar.com/avatar/3699a2727a92a410332ca568fef4353e3ae40c0b0c1fd5043585ceec77dc0e05?s=80&d=identicon',
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
            stages: {
              nodes: [
                {
                  id: 'gid://gitlab/Ci::Stage/429',
                  name: 'build',
                  status: 'success',
                  __typename: 'CiStage',
                },
                {
                  id: 'gid://gitlab/Ci::Stage/431',
                  name: 'test',
                  status: 'success',
                  __typename: 'CiStage',
                },
                {
                  id: 'gid://gitlab/Ci::Stage/434',
                  name: 'deploy',
                  status: 'success',
                  __typename: 'CiStage',
                },
              ],
              __typename: 'CiStageConnection',
            },
            mergeRequest: null,
            mergeRequestEventType: null,
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
            },
            createdAt: '2025-09-18T15:04:38Z',
            finishedAt: '2025-09-18T15:04:59Z',
            duration: 16,
            name: 'Ruby 3.0 master branch pipeline',
            ref: 'main',
            refPath: 'refs/heads/main',
            refText:
              'For <a class="ref-container gl-link" href="/root/ci-project/-/commits/main">main</a>',
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
                  'https://www.gravatar.com/avatar/3699a2727a92a410332ca568fef4353e3ae40c0b0c1fd5043585ceec77dc0e05?s=80&d=identicon',
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
                'https://www.gravatar.com/avatar/3699a2727a92a410332ca568fef4353e3ae40c0b0c1fd5043585ceec77dc0e05?s=80&d=identicon',
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
            stages: {
              nodes: [
                {
                  id: 'gid://gitlab/Ci::Stage/424',
                  name: 'build',
                  status: 'success',
                  __typename: 'CiStage',
                },
                {
                  id: 'gid://gitlab/Ci::Stage/425',
                  name: 'test',
                  status: 'success',
                  __typename: 'CiStage',
                },
                {
                  id: 'gid://gitlab/Ci::Stage/426',
                  name: 'deploy',
                  status: 'success',
                  __typename: 'CiStage',
                },
              ],
              __typename: 'CiStageConnection',
            },
            mergeRequest: null,
            mergeRequestEventType: null,
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
