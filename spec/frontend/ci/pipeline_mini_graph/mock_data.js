export const mockDownstreamPipelinesGraphql = ({ includeSourceJobRetried = true } = {}) => ({
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
        group: 'success',
        icon: 'status_success',
        label: 'passed',
        __typename: 'DetailedStatus',
      },
      sourceJob: {
        id: 'gid://gitlab/Ci::Bridge/532',
        retried: includeSourceJobRetried ? false : null,
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
        group: 'success',
        icon: 'status_success',
        label: 'passed',
        __typename: 'DetailedStatus',
      },
      sourceJob: {
        id: 'gid://gitlab/Ci::Bridge/531',
        retried: includeSourceJobRetried ? true : null,
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
        group: 'success',
        icon: 'status_success',
        label: 'passed',
        __typename: 'DetailedStatus',
      },
      sourceJob: {
        id: 'gid://gitlab/Ci::Bridge/530',
        retried: includeSourceJobRetried ? true : null,
      },
      __typename: 'Pipeline',
    },
  ],
  __typename: 'PipelineConnection',
});

const upstream = {
  id: 'gid://gitlab/Ci::Pipeline/610',
  path: '/root/trigger-downstream/-/pipelines/610',
  project: {
    id: 'gid://gitlab/Project/21',
    name: 'trigger-downstream',
    __typename: 'Project',
  },
  detailedStatus: {
    id: 'success-610-610',
    group: 'success',
    icon: 'status_success',
    label: 'passed',
    __typename: 'DetailedStatus',
  },
  __typename: 'Pipeline',
};

export const mockPipelineStagesQueryResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/20',
      pipeline: {
        id: 'gid://gitlab/Ci::Pipeline/320',
        stages: {
          nodes: [
            {
              __typename: 'CiStage',
              id: 'gid://gitlab/Ci::Stage/409',
              name: 'build',
              detailedStatus: {
                __typename: 'DetailedStatus',
                id: 'success-409-409',
                icon: 'status_success',
                group: 'success',
              },
            },
          ],
        },
      },
    },
  },
};

export const mockPipelineStatusResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/20',
      pipeline: {
        id: 'gid://gitlab/Ci::Pipeline/320',
        detailedStatus: {
          id: 'pending-320-320',
          detailsPath: '/root/ci-project/-/pipelines/320',
          icon: 'status_pending',
          group: 'pending',
          __typename: 'DetailedStatus',
        },
        __typename: 'Pipeline',
      },
      __typename: 'Project',
    },
  },
};

export const mockUpstreamDownstreamQueryResponse = {
  data: {
    project: {
      id: '1',
      pipeline: {
        id: 'pipeline-1',
        path: '/root/ci-project/-/pipelines/790',
        downstream: mockDownstreamPipelinesGraphql(),
        upstream,
      },
      __typename: 'Project',
    },
  },
};

export const linkedPipelinesFetchError = 'There was a problem fetching linked pipelines.';
export const stagesFetchError = 'There was a problem fetching the pipeline stages.';

export const stageReply = {
  name: 'deploy',
  title: 'deploy: running',
  latest_statuses: [
    {
      id: 928,
      name: 'stop staging',
      started: false,
      build_path: '/twitter/flight/-/jobs/928',
      cancel_path: '/twitter/flight/-/jobs/928/cancel',
      playable: false,
      created_at: '2018-04-04T20:02:02.728Z',
      updated_at: '2018-04-04T20:02:02.766Z',
      status: {
        icon: 'status_pending',
        text: 'pending',
        label: 'pending',
        group: 'pending',
        tooltip: 'pending',
        has_details: true,
        details_path: '/twitter/flight/-/jobs/928',
        favicon:
          '/assets/ci_favicons/dev/favicon_status_pending-db32e1faf94b9f89530ac519790920d1f18ea8f6af6cd2e0a26cd6840cacf101.ico',
        action: {
          icon: 'cancel',
          title: 'Cancel',
          path: '/twitter/flight/-/jobs/928/cancel',
          method: 'post',
        },
      },
    },
    {
      id: 926,
      name: 'production',
      started: false,
      build_path: '/twitter/flight/-/jobs/926',
      retry_path: '/twitter/flight/-/jobs/926/retry',
      play_path: '/twitter/flight/-/jobs/926/play',
      playable: true,
      created_at: '2018-04-04T20:00:57.202Z',
      updated_at: '2018-04-04T20:11:13.110Z',
      status: {
        icon: 'status_canceled',
        text: 'canceled',
        label: 'manual play action',
        group: 'canceled',
        tooltip: 'canceled',
        has_details: true,
        details_path: '/twitter/flight/-/jobs/926',
        favicon:
          '/assets/ci_favicons/dev/favicon_status_canceled-5491840b9b6feafba0bc599cbd49ee9580321dc809683856cf1b0d51532b1af6.ico',
        action: {
          icon: 'play',
          title: 'Play',
          path: '/twitter/flight/-/jobs/926/play',
          method: 'post',
        },
      },
    },
    {
      id: 217,
      name: 'staging',
      started: '2018-03-07T08:41:46.234Z',
      build_path: '/twitter/flight/-/jobs/217',
      retry_path: '/twitter/flight/-/jobs/217/retry',
      playable: false,
      created_at: '2018-03-07T14:41:58.093Z',
      updated_at: '2018-03-07T14:41:58.093Z',
      status: {
        icon: 'status_success',
        text: 'passed',
        label: 'passed',
        group: 'success',
        tooltip: 'passed',
        has_details: true,
        details_path: '/twitter/flight/-/jobs/217',
        favicon:
          '/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico',
        action: {
          icon: 'retry',
          title: 'Retry',
          path: '/twitter/flight/-/jobs/217/retry',
          method: 'post',
        },
      },
    },
  ],
  status: {
    icon: 'status_running',
    text: 'running',
    label: 'running',
    group: 'running',
    tooltip: 'running',
    has_details: true,
    details_path: '/twitter/flight/pipelines/13#deploy',
    favicon:
      '/assets/ci_favicons/dev/favicon_status_running-c3ad2fc53ea6079c174e5b6c1351ff349e99ec3af5a5622fb77b0fe53ea279c1.ico',
  },
  path: '/twitter/flight/pipelines/13#deploy',
  dropdown_path: '/twitter/flight/pipelines/13/stage.json?stage=deploy',
};
