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
