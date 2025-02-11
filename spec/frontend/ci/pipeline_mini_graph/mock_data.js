export const mockDownstreamPipelinesGraphql = {
  nodes: [
    {
      id: 'gid://gitlab/Ci::Pipeline/612',
      path: '/root/job-log-sections/-/pipelines/612',
      project: {
        id: 'gid://gitlab/Project/21',
        name: 'job-log-sections',
        __typename: 'Project',
      },
      detailedStatus: {
        id: 'success-612-612',
        detailsPath: '/root/job-log-sections/-/pipelines/612',
        icon: 'status_success',
        label: 'passed',
        __typename: 'DetailedStatus',
      },
      sourceJob: {
        id: 'gid://gitlab/Ci::Bridge/5785',
        retried: false,
        __typename: 'CiJob',
      },
      __typename: 'Pipeline',
    },
    {
      id: 'gid://gitlab/Ci::Pipeline/611',
      path: '/root/job-log-sections/-/pipelines/611',
      project: {
        id: 'gid://gitlab/Project/21',
        name: 'job-log-sections',
        __typename: 'Project',
      },
      detailedStatus: {
        id: 'success-611-611',
        detailsPath: '/root/job-log-sections/-/pipelines/611',
        icon: 'status_success',
        label: 'passed',
        __typename: 'DetailedStatus',
      },
      sourceJob: {
        id: 'gid://gitlab/Ci::Bridge/5786',
        retried: false,
        __typename: 'CiJob',
      },
      __typename: 'Pipeline',
    },
    {
      id: 'gid://gitlab/Ci::Pipeline/609',
      path: '/root/job-log-sections/-/pipelines/609',
      project: {
        id: 'gid://gitlab/Project/21',
        name: 'job-log-sections',
        __typename: 'Project',
      },
      detailedStatus: {
        id: 'success-609-609',
        detailsPath: '/root/job-log-sections/-/pipelines/609',
        icon: 'status_success',
        label: 'passed',
        __typename: 'DetailedStatus',
      },
      sourceJob: {
        id: 'gid://gitlab/Ci::Bridge/5787',
        retried: true,
        __typename: 'CiJob',
      },
      __typename: 'Pipeline',
    },
  ],
  __typename: 'PipelineConnection',
};

export const pipelineStage = {
  __typename: 'CiStage',
  id: 'gid://gitlab/Ci::Stage/409',
  name: 'build',
  scheduled: false,
  scheduledAt: null,
  detailedStatus: {
    __typename: 'DetailedStatus',
    id: 'success-409-409',
    icon: 'status_success',
    label: 'passed',
    tooltip: 'passed',
  },
};

// for `job_action_button_spec.js`
export const mockJobActions = [
  {
    __typename: 'StatusAction',
    confirmationMessage: null,
    id: 'Ci::Build-pending-1001',
    icon: 'cancel',
    path: '/flightjs/Flight/-/jobs/1001/cancel',
    title: 'Cancel',
  },
  {
    __typename: 'StatusAction',
    confirmationMessage: null,
    id: 'Ci::Build-manual-1001',
    icon: 'play',
    path: '/flightjs/Flight/-/jobs/1001/play',
    title: 'Run',
  },
  {
    __typename: 'StatusAction',
    confirmationMessage: null,
    id: 'Ci::Build-success-1001',
    icon: 'retry',
    path: '/flightjs/Flight/-/jobs/1001/retry',
    title: 'Run again',
  },
  {
    __typename: 'StatusAction',
    confirmationMessage: null,
    id: 'Ci::Build-scheduled-1001',
    icon: 'time-out',
    path: '/flightjs/Flight/-/jobs/1001/unschedule',
    title: 'Unschedule',
  },
];

export const mockJobMutationResponse = (dataName) => ({
  data: {
    [dataName]: {
      job: {
        __typename: 'CiJob',
        id: 'gid://gitlab/Ci::Build/1001',
        detailedStatus: {
          __typename: 'DetailedStatus',
          id: 'running-1001-1001',
          action: {
            __typename: 'StatusAction',
            id: 'Ci::Build-manual-1001',
            confirmationMessage: 'here is a message',
            icon: 'play',
            path: '/flightjs/Flight/-/jobs/1001/play',
            title: 'Run',
          },
        },
      },
      errors: [],
    },
  },
});

export const mockJobCancelResponse = mockJobMutationResponse('jobCancel');
export const mockJobPlayResponse = mockJobMutationResponse('jobPlay');
export const mockJobRetryResponse = mockJobMutationResponse('jobRetry');
export const mockJobUnscheduleResponse = mockJobMutationResponse('jobUnschedule');

// for `job_item_spec.js`
export const mockPipelineJob = {
  __typename: 'CiJob',
  id: 'gid://gitlab/Ci::Build/1001',
  detailedStatus: {
    __typename: 'DetailedStatus',
    id: 'running-1001-1001',
    action: {
      __typename: 'StatusAction',
      id: 'Ci::Build-success-1001',
      confirmationMessage: null,
      icon: 'cancel',
      path: '/flightjs/Flight/-/jobs/1001/cancel',
      title: 'Cancel',
    },
    detailsPath: '/flightjs/Flight/-/pipelines/1176',
    group: 'running',
    hasDetails: true,
    icon: 'status_running',
    tooltip: 'running',
  },
  name: 'test_job',
  scheduled: false,
  scheduledAt: null,
};

// for `pipeline_stage_spec.js`
export const mockPipelineStageJobs = {
  data: {
    ciPipelineStage: {
      __typename: 'CiStage',
      id: 'gid://gitlab/Ci::Stage/409',
      jobs: {
        __typename: 'CiJobConnection',
        nodes: [
          {
            __typename: 'CiJob',
            id: 'gid://gitlab/Ci::Build/1001',
            detailedStatus: {
              __typename: 'DetailedStatus',
              id: 'success-1001-1001',
              action: {
                __typename: 'StatusAction',
                id: 'Ci::Build-success-1001',
                confirmationMessage: null,
                icon: 'retry',
                path: '/flightjs/Flight/-/jobs/1001/retry',
                title: 'Retry',
              },
              detailsPath: '/flightjs/Flight/-/pipelines/1176',
              group: 'success',
              hasDetails: true,
              icon: 'status_success',
              tooltip: 'passed',
            },
            name: 'test_job',
            scheduled: false,
            scheduledAt: null,
          },
          {
            __typename: 'CiJob',
            id: 'gid://gitlab/Ci::Build/1002',
            detailedStatus: {
              __typename: 'DetailedStatus',
              id: 'success-1002-1002',
              action: {
                __typename: 'StatusAction',
                id: 'Ci::Build-success-1002',
                confirmationMessage: null,
                icon: 'retry',
                path: '/flightjs/Flight/-/jobs/1001/retry',
                title: 'Retry',
              },
              detailsPath: '/flightjs/Flight/-/pipelines/1176',
              group: 'failed',
              hasDetails: true,
              icon: 'status_failed',
              tooltip: 'failed',
            },
            name: 'test_job_2',
            scheduled: false,
            scheduledAt: null,
          },
        ],
      },
    },
  },
};

export const singlePipeline = {
  id: 'gid://gitlab/Ci::Pipeline/610',
  iid: 234,
  detailedStatus: {
    id: 'success-610-610',
    detailsPath: '/root/trigger-downstream/-/pipelines/610',
    icon: 'status_success',
    label: 'passed',
    __typename: 'DetailedStatus',
  },
  path: '/path/to/pipeline',
  project: {
    id: 'gid://gitlab/Project/21',
    name: 'trigger-downstream',
    fullPath: 'full/path',
    __typename: 'Project',
  },
  __typename: 'Pipeline',
};

export const pipelineStageJobsFetchError = 'There was a problem fetching the pipeline stage jobs.';

export const downstreamPipelines = [
  {
    id: 'gid://gitlab/Ci::Pipeline/612',
    path: '/root/job-log-sections/-/pipelines/612',
    project: {
      id: 'gid://gitlab/Project/21',
      name: 'job-log-sections',
    },
    detailedStatus: {
      id: 'success-612-612',
      detailsPath: '/hello',
      icon: 'status_success',
      label: 'passed',
    },
    sourceJob: {
      id: 'gid://gitlab/Ci::Bridge/5785',
      retried: false,
    },
  },
  {
    id: 'gid://gitlab/Ci::Pipeline/611',
    path: '/root/job-log-sections/-/pipelines/611',
    project: {
      id: 'gid://gitlab/Project/21',
      name: 'job-log-sections',
    },
    detailedStatus: {
      id: 'success-611-611',
      detailsPath: '/hello',
      icon: 'status_success',
      label: 'passed',
    },
    sourceJob: {
      id: 'gid://gitlab/Ci::Bridge/5785',
      retried: false,
    },
  },
  {
    id: 'gid://gitlab/Ci::Pipeline/609',
    path: '/root/job-log-sections/-/pipelines/609',
    project: {
      id: 'gid://gitlab/Project/21',
      name: 'job-log-sections',
    },
    detailedStatus: {
      id: 'success-609-609',
      detailsPath: '/hello',
      icon: 'status_success',
      label: 'passed',
    },
    sourceJob: {
      id: 'gid://gitlab/Ci::Bridge/5785',
      retried: false,
    },
  },
  {
    id: 'gid://gitlab/Ci::Pipeline/610',
    path: '/root/test-project/-/pipelines/610',
    project: {
      id: 'gid://gitlab/Project/22',
      name: 'test-project',
    },
    detailedStatus: {
      id: 'success-609-609',
      detailsPath: '/hello',
      icon: 'status_success',
      label: 'passed',
    },
    sourceJob: {
      id: 'gid://gitlab/Ci::Bridge/5785',
      retried: false,
    },
  },
];
