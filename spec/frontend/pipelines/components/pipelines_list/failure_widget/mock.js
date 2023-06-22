export const job = {
  id: 'gid://gitlab/Ci::Build/5241',
  allowFailure: false,
  detailedStatus: {
    id: 'status',
    action: {
      id: 'action',
      path: '/retry',
      icon: 'retry',
    },
    group: 'running',
    icon: 'running-icon',
  },
  name: 'job-name',
  retried: false,
  retryable: true,
  stage: {
    id: '1',
    name: 'build',
  },
  trace: {
    htmlSummary: '<h1>Hello</h1>',
  },
  userPermissions: {
    readBuild: true,
    updateBuild: true,
  },
  webPath: '/',
};

export const allowedToFailJob = {
  ...job,
  id: 'gid://gitlab/Ci::Build/5242',
  allowFailure: true,
};

export const failedJobsMock = {
  data: {
    project: {
      id: 'gid://gitlab/Project/20',
      pipeline: {
        id: 'gid://gitlab/Pipeline/20',
        jobs: {
          nodes: [allowedToFailJob, job],
        },
      },
    },
  },
};

export const failedJobsMock2 = {
  data: {
    project: {
      id: 'gid://gitlab/Project/20',
      pipeline: {
        id: 'gid://gitlab/Pipeline/20',
        jobs: {
          nodes: [job],
        },
      },
    },
  },
};
