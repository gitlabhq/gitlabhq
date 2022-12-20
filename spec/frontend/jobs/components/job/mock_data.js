export const mockFullPath = 'Commit451/lab-coat';
export const mockId = 401;

export const mockJobResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/4',
      job: {
        id: 'gid://gitlab/Ci::Build/401',
        manualJob: true,
        manualVariables: {
          nodes: [],
          __typename: 'CiManualVariableConnection',
        },
        name: 'manual_job',
        retryable: true,
        status: 'SUCCESS',
        __typename: 'CiJob',
      },
      __typename: 'Project',
    },
  },
};

export const mockJobWithVariablesResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/4',
      job: {
        id: 'gid://gitlab/Ci::Build/401',
        manualJob: true,
        manualVariables: {
          nodes: [
            {
              id: 'gid://gitlab/Ci::JobVariable/150',
              key: 'new key',
              value: 'new value',
              __typename: 'CiManualVariable',
            },
          ],
          __typename: 'CiManualVariableConnection',
        },
        name: 'manual_job',
        retryable: true,
        status: 'SUCCESS',
        __typename: 'CiJob',
      },
      __typename: 'Project',
    },
  },
};

export const mockJobMutationData = {
  data: {
    jobRetry: {
      job: {
        id: 'gid://gitlab/Ci::Build/401',
        manualVariables: {
          nodes: [
            {
              id: 'gid://gitlab/Ci::JobVariable/151',
              key: 'new key',
              value: 'new value',
              __typename: 'CiManualVariable',
            },
          ],
          __typename: 'CiManualVariableConnection',
        },
        webPath: '/Commit451/lab-coat/-/jobs/401',
        __typename: 'CiJob',
      },
      errors: [],
      __typename: 'JobRetryPayload',
    },
  },
};
