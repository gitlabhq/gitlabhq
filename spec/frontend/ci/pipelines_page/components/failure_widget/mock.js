export const job = {
  id: 'gid://gitlab/Ci::Build/5241',
  allowFailure: false,
  detailedStatus: {
    id: 'status',
    detailsPath: '/jobs/5241',
    action: {
      id: 'action',
      path: '/retry',
      icon: 'retry',
    },
    group: 'running',
    icon: 'status_running_icon',
  },
  name: 'job-name',
  retried: false,
  retryable: true,
  kind: 'BUILD',
  stage: {
    id: '1',
    name: 'build',
  },
  userPermissions: {
    readBuild: true,
    updateBuild: true,
  },
};

export const allowedToFailJob = {
  ...job,
  id: 'gid://gitlab/Ci::Build/5242',
  allowFailure: true,
};

export const createFailedJobsMockCount = (count = 4, active = false) => {
  return {
    data: {
      project: {
        id: 'gid://gitlab/Project/20',
        pipeline: {
          id: 'gid://gitlab/Pipeline/20',
          active,
          jobs: {
            count,
          },
        },
      },
    },
  };
};

const createFailedJobsMock = (nodes, active = false) => {
  return {
    data: {
      project: {
        id: 'gid://gitlab/Project/20',
        pipeline: {
          active,
          troubleshootJobWithAi: true,
          id: 'gid://gitlab/Pipeline/20',
          jobs: {
            count: nodes.length,
            nodes,
          },
        },
      },
    },
  };
};

export const failedJobsMock = createFailedJobsMock([allowedToFailJob, job]);
export const failedJobsMockEmpty = createFailedJobsMock([]);

export const activeFailedJobsMock = createFailedJobsMock([allowedToFailJob, job], true);

export const failedJobsMock2 = createFailedJobsMock([job]);

export const failedJobsCountMock = createFailedJobsMockCount();
export const failedJobsCountMockActive = createFailedJobsMockCount(4, true);
