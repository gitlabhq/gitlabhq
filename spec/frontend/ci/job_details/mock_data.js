export const mockFullPath = 'Commit451/lab-coat';
export const mockId = 401;

export const mockJobResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/20',
      job: {
        id: 'gid://gitlab/Ci::Build/13051',
        manualVariables: {
          nodes: [],
          __typename: 'CiManualVariableConnection',
        },
        __typename: 'CiJob',
        manualJob: false,
        name: 'artifact_job',
        detailedStatus: {
          id: 'success-13051-13051',
          icon: 'status_success',
          text: 'Passed',
          detailsPath: '/root/ci-project/-/jobs/13051',
          __typename: 'DetailedStatus',
        },
        startedAt: '',
        createdAt: '2025-04-21T16:19:15Z',
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
        detailedStatus: {
          id: 'manual-13046-13046',
          icon: 'status_manual',
          text: 'Manual',
          detailsPath: '/root/ci-project/-/jobs/13046',
          __typename: 'DetailedStatus',
        },
        startedAt: null,
        createdAt: '2025-04-21T16:19:15Z',
        __typename: 'CiJob',
      },
      __typename: 'Project',
    },
  },
};

export const mockJobPlayMutationData = {
  data: {
    jobPlay: {
      job: {
        id: 'gid://gitlab/Ci::Build/401',
        name: 'playable_job',
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
      __typename: 'JobPlayPayload',
    },
  },
};

export const mockJobRetryMutationData = {
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

export const mockPendingJobData = {
  has_trace: false,
  status: {
    group: 'pending',
    icon: 'status_pending',
    label: 'pending',
    text: 'pending',
    details_path: 'path',
    illustration: {
      image: 'path',
      size: '340',
      title: '',
      content: '',
    },
    action: {
      button_title: 'Retry job',
      method: 'post',
      path: '/path',
    },
  },
};
