export const MOCK_EMPTY_ILLUSTRATION_PATH = '/path/to/svg';
export const MOCK_PATH_TO_DOWNSTREAM = '/path/to/downstream/pipeline';
export const MOCK_BUILD_ID = '1331';
export const MOCK_PIPELINE_IID = '174';
export const MOCK_PROJECT_FULL_PATH = '/root/project/';
export const MOCK_SHA = '38f3d89147765427a7ce58be28cd76d14efa682a';

export const mockCommit = {
  id: `gid://gitlab/CommitPresenter/${MOCK_SHA}`,
  shortId: '38f3d891',
  title: 'Update .gitlab-ci.yml file',
  webPath: `/root/project/-/commit/${MOCK_SHA}`,
  __typename: 'Commit',
};

export const mockJob = {
  createdAt: '2021-12-10T09:05:45Z',
  id: 'gid://gitlab/Ci::Build/1331',
  name: 'triggerJobName',
  scheduledAt: null,
  startedAt: '2021-12-10T09:13:43Z',
  status: 'SUCCESS',
  triggered: null,
  detailedStatus: {
    id: '1',
    detailsPath: '/root/project/-/jobs/1331',
    icon: 'status_success',
    group: 'success',
    text: 'passed',
    tooltip: 'passed',
    __typename: 'DetailedStatus',
  },
  downstreamPipeline: {
    id: '1',
    path: '/root/project/-/pipelines/175',
  },
  stage: {
    id: '1',
    name: 'build',
    __typename: 'CiStage',
  },
  __typename: 'CiJob',
};

export const mockUser = {
  id: 'gid://gitlab/User/1',
  avatarUrl: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
  name: 'Administrator',
  username: 'root',
  webPath: '/root',
  webUrl: 'http://gdk.test:3000/root',
  status: {
    message: 'making great things',
    __typename: 'UserStatus',
  },
  __typename: 'UserCore',
};

export const mockStage = {
  id: '1',
  name: 'build',
  jobs: {
    nodes: [mockJob],
    __typename: 'CiJobConnection',
  },
  __typename: 'CiStage',
};

export const mockPipelineQueryResponse = {
  data: {
    project: {
      id: '1',
      pipeline: {
        commit: mockCommit,
        id: 'gid://gitlab/Ci::Pipeline/174',
        iid: '88',
        path: '/root/project/-/pipelines/174',
        sha: MOCK_SHA,
        ref: 'main',
        refPath: 'path/to/ref',
        user: mockUser,
        detailedStatus: {
          id: '1',
          icon: 'status_failed',
          group: 'failed',
          __typename: 'DetailedStatus',
        },
        stages: {
          edges: [
            {
              node: mockStage,
              __typename: 'CiStageEdge',
            },
          ],
          __typename: 'CiStageConnection',
        },
        __typename: 'Pipeline',
      },
      __typename: 'Project',
    },
  },
};
