export const generateMockPipeline = ({
  id = '123',
  mergeRequestEventType = 'DETACHED',
  status = 'SUCCESS',
} = {}) => ({
  id: `gid://gitlab/Ci::Pipeline/${id}`,
  iid: id,
  path: `/project/pipelines/${id}`,
  duration: 1000,
  name: null,
  createdAt: '2024-01-15T10:29:00Z',
  finishedAt: '2024-01-15T10:30:00Z',
  configSource: 'REPOSITORY_SOURCE',
  mergeRequestEventType,
  stuck: false,
  failureReason: null,
  yamlErrors: false,
  latest: true,
  retryable: true,
  cancelable: false,
  ref: 'refs/merge-requests/1/head',
  refPath: 'refs/heads/root-main-patch-56329',
  refText: '',
  source: 'merge_request_event',
  type: 'merge_request',
  hasManualActions: true,
  hasScheduledActions: false,
  commit: {
    id: 'gid://gitlab/Ci::Commit/1',
    name: "Merge branch '419724-apollo-mr-pipelines-build-pipeline-table-component-2' into 'master' ",
    title:
      "Merge branch '419724-apollo-mr-pipelines-build-pipeline-table-component-2' into 'master' ",
    webPath: '/gitlab-org/gitlab/-/commit/a43ea6d3a453f8e603fb3558024c084c45c0c9e4',
    webUrl: '/gitlab-org/gitlab/-/commit/a43ea6d3a453f8e603fb3558024c084c45c0c9e4',
    shortId: 'a43ea6d3',
    sha: 'a43ea6d3fc81257b1caeeaceb21b36349110ad54',
    authorGravatar:
      'https://secure.gravatar.com/avatar/295d89332b1f3e65933ee72a5f1a6081dc048333a42a5dd2bb8e81fd45590b30?s=80&d=identicon',
    author: {
      id: '1',
      avatarUrl: '/uploads/-/system/user/avatar/5327378/avatar.png',
      commitEmail: 'rando@gitlab.com',
      name: 'Random User',
      webUrl: 'https://gitlab.com/random_user',
      webPath: '/random_user',
    },
  },
  detailedStatus: {
    id: `${status.toLowerCase()}-${id}-${id}`,
    hasDetails: true,
    detailsPath: `/gitlab-org/gitlab/-/pipelines/${id}`,
    label: status.toLowerCase(),
    name: status,
  },
  stages: {
    nodes: [
      {
        id: 'gid://gitlab/Ci::Stage/1949',
        name: 'build',
        detailedStatus: {
          id: 'success-1949-1949',
          icon: 'status_success',
          text: 'Passed',
          detailsPath: `/gitlab-org/gitlab/-/pipelines/${id}#build`,
          tooltip: 'passed',
        },
      },
      {
        id: 'gid://gitlab/Ci::Stage/1950',
        name: 'test',
        detailedStatus: {
          id: 'success-1950-1950',
          icon: 'status_success',
          text: 'Passed',
          detailsPath: `/gitlab-org/gitlab/-/pipelines/${id}#test`,
          tooltip: 'passed',
        },
      },
      {
        id: 'gid://gitlab/Ci::Stage/1951',
        name: 'deploy',
        detailedStatus: {
          id: 'success-1951-1951',
          icon: 'status_success',
          text: 'Passed',
          detailsPath: `/gitlab-org/gitlab/-/pipelines/${id}#deploy`,
          tooltip: 'passed',
        },
      },
    ],
  },
  mergeRequest: {
    id: 'gid://gitlab/MergeRequest/1',
    iid: '1',
    webPath: '/gitlab-org/gitlab/-/merge_requests/1',
    title: 'Edit README.md',
  },
  project: {
    id: 'gid://gitlab/Project/1',
    fullPath: 'gitlab-org/gitlab',
  },
  user: {
    id: 'gid://gitlab/User/1',
    avatar_url: '/uploads/-/system/user/avatar/5327378/avatar.png',
    name: 'Random User',
    path: '/random_user',
    webPath: '/random_user',
  },
});

const createMergeRequestPipelines = ({ mergeRequestEventType = 'MERGE_TRAIN', count = 1 } = {}) => {
  const pipelines = [];

  for (let i = 0; i < count; i += 1) {
    pipelines.push(
      generateMockPipeline({ id: String(i), mergeRequestEventType, status: 'SKIPPED' }),
    );
  }

  return {
    count,
    nodes: pipelines,
    pageInfo: {
      hasNextPage: true,
      hasPreviousPage: false,
      startCursor: 'eyJpZCI6IjcwMSJ9',
      endCursor: 'eyJpZCI6IjY3NSJ9',
      __typename: 'PageInfo',
    },
  };
};

export const generateMRPipelinesResponse = ({ mergeRequestEventType = '', count = 1 } = {}) => {
  return {
    data: {
      project: {
        __typename: 'Project',
        id: 'gid://gitlab/Project/1',
        fullPath: 'root/project-1',
        mergeRequest: {
          __typename: 'MergeRequest',
          id: 'gid://gitlab/MergeRequest/1',
          iid: '1',
          title: 'Fix everything',
          webPath: '/merge_requests/1',
          pipelines: createMergeRequestPipelines({ count, mergeRequestEventType }),
        },
      },
    },
  };
};
