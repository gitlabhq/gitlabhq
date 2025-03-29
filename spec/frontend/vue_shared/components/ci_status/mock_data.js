export const mockPipelineStatusResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/20',
      pipeline: {
        id: 'gid://gitlab/Ci::Pipeline/1257',
        detailedStatus: {
          label: 'running',
          id: 'running-1257-1257',
          icon: 'status_running',
          text: 'Running',
          detailsPath: '/root/ci-project/-/pipelines/1257',
          __typename: 'DetailedStatus',
        },
        __typename: 'Pipeline',
      },
      __typename: 'Project',
    },
  },
};

export const mockPipelineStatusUpdatedResponse = {
  data: {
    ciPipelineStatusUpdated: {
      id: 'gid://gitlab/Ci::Pipeline/1257',
      __typename: 'Pipeline',
      detailedStatus: {
        detailsPath: '/root/simple-ci-project/-/pipelines/1257',
        icon: 'status_success',
        id: 'success-1255-1255',
        label: 'passed',
        text: 'Passed',
        __typename: 'DetailedStatus',
      },
    },
  },
};
