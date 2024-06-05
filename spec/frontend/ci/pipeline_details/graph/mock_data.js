import mockPipelineResponse from 'test_fixtures/pipelines/pipeline_details.json';
import { unwrapPipelineData } from '~/ci/pipeline_details/graph/utils';
import {
  BUILD_KIND,
  BRIDGE_KIND,
  RETRY_ACTION_TITLE,
  MANUAL_ACTION_TITLE,
} from '~/ci/pipeline_details/graph/constants';

// We mock this instead of using fixtures for performance reason.
const mockPipelineResponseCopy = JSON.parse(JSON.stringify(mockPipelineResponse));
const groups = new Array(100).fill({
  ...mockPipelineResponse.data.project.pipeline.stages.nodes[0].groups.nodes[0],
});
mockPipelineResponseCopy.data.project.pipeline.stages.nodes[0].groups.nodes = groups;
export const mockPipelineResponseWithTooManyJobs = mockPipelineResponseCopy;

export const downstream = {
  nodes: [
    {
      id: 175,
      iid: '31',
      path: '/root/elemenohpee/-/pipelines/175',
      retryable: true,
      cancelable: false,
      userPermissions: {
        updatePipeline: true,
      },
      status: {
        id: '70',
        group: 'success',
        label: 'passed',
        icon: 'status_success',
        text: 'Success',
        __typename: 'DetailedStatus',
      },
      sourceJob: {
        name: 'test_c',
        id: '71',
        retried: false,
        __typename: 'CiJob',
      },
      project: {
        id: 'gid://gitlab/Project/25',
        name: 'elemenohpee',
        fullPath: 'root/elemenohpee',
        __typename: 'Project',
      },
      __typename: 'Pipeline',
      multiproject: true,
    },
    {
      id: 181,
      iid: '27',
      path: '/root/abcd-dag/-/pipelines/181',
      retryable: true,
      cancelable: false,
      userPermissions: {
        updatePipeline: true,
      },
      status: {
        id: '72',
        group: 'success',
        label: 'passed',
        icon: 'status_success',
        text: 'Success',
        __typename: 'DetailedStatus',
      },
      sourceJob: {
        id: '73',
        name: 'test_d',
        retried: true,
        __typename: 'CiJob',
      },
      project: {
        id: 'gid://gitlab/Project/23',
        name: 'abcd-dag',
        fullPath: 'root/abcd-dag',
        __typename: 'Project',
      },
      __typename: 'Pipeline',
      multiproject: false,
    },
  ],
};

export const upstream = {
  id: 161,
  iid: '24',
  path: '/root/abcd-dag/-/pipelines/161',
  retryable: true,
  cancelable: false,
  userPermissions: {
    updatePipeline: true,
  },
  status: {
    id: '74',
    group: 'success',
    label: 'passed',
    icon: 'status_success',
    text: 'Success',
    __typename: 'DetailedStatus',
  },
  sourceJob: null,
  project: {
    id: 'gid://gitlab/Project/23',
    name: 'abcd-dag',
    fullPath: 'root/abcd-dag',
    __typename: 'Project',
  },
  __typename: 'Pipeline',
  multiproject: true,
};

export const wrappedPipelineReturn = {
  data: {
    project: {
      __typename: 'Project',
      id: '75',
      pipeline: {
        __typename: 'Pipeline',
        id: 'gid://gitlab/Ci::Pipeline/175',
        iid: '38',
        complete: true,
        usesNeeds: true,
        userPermissions: {
          __typename: 'PipelinePermissions',
          updatePipeline: true,
        },
        downstream: {
          retryable: true,
          cancelable: false,
          userPermissions: {
            updatePipeline: true,
          },
          __typename: 'PipelineConnection',
          nodes: [],
        },
        upstream: {
          id: 'gid://gitlab/Ci::Pipeline/174',
          iid: '37',
          path: '/root/elemenohpee/-/pipelines/174',
          retryable: true,
          cancelable: false,
          userPermissions: {
            updatePipeline: true,
          },
          __typename: 'Pipeline',
          status: {
            __typename: 'DetailedStatus',
            id: '77',
            group: 'success',
            label: 'passed',
            icon: 'status_success',
            text: 'Success',
          },
          sourceJob: {
            name: 'test_c',
            id: '78',
            retried: false,
            __typename: 'CiJob',
          },
          project: {
            id: 'gid://gitlab/Project/25',
            name: 'elemenohpee',
            fullPath: 'root/elemenohpee',
            __typename: 'Project',
          },
        },
        stages: {
          __typename: 'CiStageConnection',
          nodes: [
            {
              name: 'build',
              __typename: 'CiStage',
              id: '79',
              status: {
                action: null,
                id: '80',
                __typename: 'DetailedStatus',
              },
              groups: {
                __typename: 'CiGroupConnection',
                nodes: [
                  {
                    __typename: 'CiGroup',
                    id: '81',
                    status: {
                      __typename: 'DetailedStatus',
                      id: '82',
                      label: 'passed',
                      group: 'success',
                      icon: 'status_success',
                      text: 'Success',
                    },
                    name: 'build_n',
                    size: 1,
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          id: '83',
                          kind: BUILD_KIND,
                          name: 'build_n',
                          scheduledAt: null,
                          needs: {
                            __typename: 'CiBuildNeedConnection',
                            nodes: [],
                          },
                          previousStageJobsOrNeeds: {
                            __typename: 'CiJobConnection',
                            nodes: [],
                          },
                          status: {
                            __typename: 'DetailedStatus',
                            id: '84',
                            icon: 'status_success',
                            text: 'Success',
                            tooltip: 'passed',
                            label: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/elemenohpee/-/jobs/1662',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
                              id: '85',
                              buttonTitle: 'Retry this job',
                              icon: 'retry',
                              path: '/root/elemenohpee/-/jobs/1662/retry',
                              title: 'Retry',
                              confirmationMessage: null,
                            },
                          },
                        },
                      ],
                    },
                  },
                ],
              },
            },
          ],
        },
      },
    },
  },
};

export const generateResponse = (raw, mockPath) => unwrapPipelineData(mockPath, raw.data);

export const pipelineWithUpstreamDownstream = (base) => {
  const pip = { ...base };
  pip.data.project.pipeline.downstream = downstream;
  pip.data.project.pipeline.upstream = upstream;

  return generateResponse(pip, 'root/abcd-dag');
};

export const mapCallouts = (callouts) =>
  callouts.map((callout) => {
    return { featureName: callout, __typename: 'UserCallout' };
  });

export const mockCalloutsResponse = (mappedCallouts) => ({
  data: {
    currentUser: {
      id: 45,
      __typename: 'User',
      callouts: {
        id: 5,
        __typename: 'UserCalloutConnection',
        nodes: mappedCallouts,
      },
    },
  },
});

export const delayedJob = {
  __typename: 'CiJob',
  kind: BUILD_KIND,
  name: 'delayed job',
  scheduledAt: '2015-07-03T10:01:00.000Z',
  needs: [],
  status: {
    __typename: 'DetailedStatus',
    icon: 'status_scheduled',
    tooltip: 'delayed manual action (%{remainingTime})',
    hasDetails: true,
    detailsPath: '/root/kinder-pipe/-/jobs/5339',
    group: 'scheduled',
    text: 'Success',
    action: {
      __typename: 'StatusAction',
      icon: 'time-out',
      title: 'Unschedule',
      path: '/frontend-fixtures/builds-project/-/jobs/142/unschedule',
      buttonTitle: 'Unschedule job',
    },
  },
};

export const mockJob = {
  id: 4256,
  name: 'test',
  kind: BUILD_KIND,
  status: {
    icon: 'status_success',
    text: 'passed',
    label: 'passed',
    tooltip: 'passed',
    group: 'success',
    detailsPath: '/root/ci-mock/builds/4256',
    hasDetails: true,
    action: {
      icon: 'retry',
      title: 'Retry',
      path: '/root/ci-mock/builds/4256/retry',
      method: 'post',
    },
  },
};

export const mockJobWithoutDetails = {
  id: 4257,
  name: 'job_without_details',
  status: {
    icon: 'status_success',
    text: 'passed',
    label: 'passed',
    group: 'success',
    detailsPath: '/root/ci-mock/builds/4257',
    hasDetails: false,
  },
};

export const mockJobWithUnauthorizedAction = {
  id: 4258,
  name: 'stop-environment',
  status: {
    icon: 'status_manual',
    label: 'manual stop action (not allowed)',
    tooltip: 'manual action',
    group: 'manual',
    detailsPath: '/root/ci-mock/builds/4258',
    hasDetails: true,
    action: null,
  },
};

export const triggerJob = {
  id: 4259,
  name: 'trigger',
  kind: BRIDGE_KIND,
  status: {
    icon: 'status_success',
    text: 'passed',
    label: 'passed',
    group: 'success',
    action: null,
  },
};

export const triggerManualJob = {
  ...triggerJob,
  status: {
    ...triggerJob.status,
    action: {
      icon: 'play',
      title: MANUAL_ACTION_TITLE,
      path: '/root/ci-mock/builds/4259/play',
      method: 'post',
      confirmationMessage: null,
    },
  },
};

export const triggerJobWithRetryAction = {
  ...triggerJob,
  status: {
    ...triggerJob.status,
    action: {
      icon: 'retry',
      title: RETRY_ACTION_TITLE,
      path: '/root/ci-mock/builds/4259/retry',
      method: 'post',
      confirmationMessage: null,
    },
  },
};

export const mockFailedJob = {
  id: 3999,
  name: 'failed job',
  kind: BUILD_KIND,
  status: {
    id: 'failed-3999-3999',
    icon: 'status_failed',
    tooltip: 'failed - (stuck or timeout failure)',
    hasDetails: true,
    detailsPath: '/root/ci-project/-/jobs/3999',
    group: 'failed',
    label: 'failed',
    action: {
      id: 'Ci::BuildPresenter-failed-3999',
      buttonTitle: 'Retry this job',
      icon: 'retry',
      path: '/root/ci-project/-/jobs/3999/retry',
      title: 'Retry',
    },
  },
};
