const createMergeRequestPipelines = ({ mergeRequestEventType = 'MERGE_TRAIN', count = 1 } = {}) => {
  const pipelines = [];

  for (let i = 0; i < count; i += 1) {
    pipelines.push({
      id: `gid://gitlab/Ci::Pipeline/${i}`,
      iid: `gid://gitlab/Ci::Pipeline/${i + 10}`,
      path: `/project/pipelines/${i}`,
      duration: 1000,
      name: null,
      finishedAt: null,
      configSource: 'REPOSITORY_SOURCE',
      mergeRequestEventType,
      stuck: false,
      failureReason: null,
      yamlErrors: false,
      latest: true,
      retryable: true,
      cancelable: false,
      commit: {
        id: 'gid://gitlab/Ci::Commit/1',
        title:
          "Merge branch '419724-apollo-mr-pipelines-build-pipeline-table-component-2' into 'master' ",
        webPath: '/gitlab-org/gitlab/-/commit/a43ea6d3a453f8e603fb3558024c084c45c0c9e4',
        shortId: 'a43ea6d3',
        authorGravatar:
          'https://secure.gravatar.com/avatar/295d89332b1f3e65933ee72a5f1a6081dc048333a42a5dd2bb8e81fd45590b30?s=80&d=identicon',
        author: {
          id: '1',
          avatarUrl: '/uploads/-/system/user/avatar/5327378/avatar.png',
          commitEmail: 'rando@gitlab.com',
          name: 'Random User',
          webUrl: 'https://gitlab.com/random_user',
        },
      },
      detailedStatus: {
        id: '1',
        hasDetails: true,
        detailsPath: `/gitlab-org/gitlab/-/pipelines/${i}`,
        label: 'skipped',
        name: 'SKIPPED',
      },
      user: {
        id: 'gid://gitlab/User/1',
        avatar_url: '/uploads/-/system/user/avatar/5327378/avatar.png',
        name: 'Random User',
        path: '/random_user',
      },
    });
  }

  return {
    count,
    nodes: pipelines,
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
