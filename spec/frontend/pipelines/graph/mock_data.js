import { unwrapPipelineData } from '~/pipelines/components/graph/utils';
import {
  BUILD_KIND,
  BRIDGE_KIND,
  RETRY_ACTION_TITLE,
} from '~/pipelines/components/graph/constants';

export const mockPipelineResponse = {
  data: {
    project: {
      __typename: 'Project',
      id: '1',
      pipeline: {
        __typename: 'Pipeline',
        id: 163,
        iid: '22',
        complete: true,
        usesNeeds: true,
        downstream: null,
        upstream: null,
        userPermissions: {
          __typename: 'PipelinePermissions',
          updatePipeline: true,
        },
        stages: {
          __typename: 'CiStageConnection',
          nodes: [
            {
              __typename: 'CiStage',
              id: '2',
              name: 'build',
              status: {
                __typename: 'DetailedStatus',
                id: '3',
                action: null,
              },
              groups: {
                __typename: 'CiGroupConnection',
                nodes: [
                  {
                    __typename: 'CiGroup',
                    id: '4',
                    name: 'build_a_nlfjkdnlvskfnksvjknlfdjvlvnjdkjdf_nvjkenjkrlngjeknjkl',
                    size: 1,
                    status: {
                      __typename: 'DetailedStatus',
                      id: '5',
                      label: 'passed',
                      group: 'success',
                      icon: 'status_success',
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          id: '6',
                          kind: BUILD_KIND,
                          name: 'build_a_nlfjkdnlvskfnksvjknlfdjvlvnjdkjdf_nvjkenjkrlngjeknjkl',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            id: '7',
                            icon: 'status_success',
                            tooltip: 'passed',
                            label: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1482',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
                              id: '8',
                              buttonTitle: 'Retry this job',
                              icon: 'retry',
                              path: '/root/abcd-dag/-/jobs/1482/retry',
                              title: 'Retry',
                            },
                          },
                          needs: {
                            __typename: 'CiBuildNeedConnection',
                            nodes: [],
                          },
                          previousStageJobsOrNeeds: {
                            __typename: 'CiJobConnection',
                            nodes: [],
                          },
                        },
                      ],
                    },
                  },
                  {
                    __typename: 'CiGroup',
                    name: 'build_b',
                    id: '9',
                    size: 1,
                    status: {
                      __typename: 'DetailedStatus',
                      id: '10',
                      label: 'passed',
                      group: 'success',
                      icon: 'status_success',
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          id: '11',
                          name: 'build_b',
                          kind: BUILD_KIND,
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            id: '12',
                            icon: 'status_success',
                            tooltip: 'passed',
                            label: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1515',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
                              id: '13',
                              buttonTitle: 'Retry this job',
                              icon: 'retry',
                              path: '/root/abcd-dag/-/jobs/1515/retry',
                              title: 'Retry',
                            },
                          },
                          needs: {
                            __typename: 'CiBuildNeedConnection',
                            nodes: [],
                          },
                          previousStageJobsOrNeeds: {
                            __typename: 'CiJobConnection',
                            nodes: [],
                          },
                        },
                      ],
                    },
                  },
                  {
                    __typename: 'CiGroup',
                    id: '14',
                    name: 'build_c',
                    size: 1,
                    status: {
                      __typename: 'DetailedStatus',
                      id: '15',
                      label: 'passed',
                      group: 'success',
                      icon: 'status_success',
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          id: '16',
                          name: 'build_c',
                          kind: BUILD_KIND,
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            id: '17',
                            icon: 'status_success',
                            tooltip: 'passed',
                            label: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1484',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
                              id: '18',
                              buttonTitle: 'Retry this job',
                              icon: 'retry',
                              path: '/root/abcd-dag/-/jobs/1484/retry',
                              title: 'Retry',
                            },
                          },
                          needs: {
                            __typename: 'CiBuildNeedConnection',
                            nodes: [],
                          },
                          previousStageJobsOrNeeds: {
                            __typename: 'CiJobConnection',
                            nodes: [],
                          },
                        },
                      ],
                    },
                  },
                  {
                    __typename: 'CiGroup',
                    id: '19',
                    name: 'build_d',
                    size: 3,
                    status: {
                      __typename: 'DetailedStatus',
                      id: '20',
                      label: 'passed',
                      group: 'success',
                      icon: 'status_success',
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          id: '21',
                          kind: BUILD_KIND,
                          name: 'build_d 1/3',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            id: '22',
                            icon: 'status_success',
                            tooltip: 'passed',
                            label: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1485',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
                              id: '23',
                              buttonTitle: 'Retry this job',
                              icon: 'retry',
                              path: '/root/abcd-dag/-/jobs/1485/retry',
                              title: 'Retry',
                            },
                          },
                          needs: {
                            __typename: 'CiBuildNeedConnection',
                            nodes: [],
                          },
                          previousStageJobsOrNeeds: {
                            __typename: 'CiJobConnection',
                            nodes: [],
                          },
                        },
                        {
                          __typename: 'CiJob',
                          id: '24',
                          kind: BUILD_KIND,
                          name: 'build_d 2/3',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            id: '25',
                            icon: 'status_success',
                            tooltip: 'passed',
                            label: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1486',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
                              id: '26',
                              buttonTitle: 'Retry this job',
                              icon: 'retry',
                              path: '/root/abcd-dag/-/jobs/1486/retry',
                              title: 'Retry',
                            },
                          },
                          needs: {
                            __typename: 'CiBuildNeedConnection',
                            nodes: [],
                          },
                          previousStageJobsOrNeeds: {
                            __typename: 'CiJobConnection',
                            nodes: [],
                          },
                        },
                        {
                          __typename: 'CiJob',
                          id: '27',
                          kind: BUILD_KIND,
                          name: 'build_d 3/3',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            id: '28',
                            icon: 'status_success',
                            tooltip: 'passed',
                            label: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1487',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
                              id: '29',
                              buttonTitle: 'Retry this job',
                              icon: 'retry',
                              path: '/root/abcd-dag/-/jobs/1487/retry',
                              title: 'Retry',
                            },
                          },
                          needs: {
                            __typename: 'CiBuildNeedConnection',
                            nodes: [],
                          },
                          previousStageJobsOrNeeds: {
                            __typename: 'CiJobConnection',
                            nodes: [],
                          },
                        },
                      ],
                    },
                  },
                ],
              },
            },
            {
              __typename: 'CiStage',
              id: '30',
              name: 'test',
              status: {
                __typename: 'DetailedStatus',
                id: '31',
                action: null,
              },
              groups: {
                __typename: 'CiGroupConnection',
                nodes: [
                  {
                    __typename: 'CiGroup',
                    id: '32',
                    name: 'test_a',
                    size: 1,
                    status: {
                      __typename: 'DetailedStatus',
                      id: '33',
                      label: 'passed',
                      group: 'success',
                      icon: 'status_success',
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          id: '34',
                          kind: BUILD_KIND,
                          name: 'test_a',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            id: '35',
                            icon: 'status_success',
                            tooltip: 'passed',
                            label: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1514',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
                              id: '36',
                              buttonTitle: 'Retry this job',
                              icon: 'retry',
                              path: '/root/abcd-dag/-/jobs/1514/retry',
                              title: 'Retry',
                            },
                          },
                          needs: {
                            __typename: 'CiBuildNeedConnection',
                            nodes: [
                              {
                                __typename: 'CiBuildNeed',
                                id: '37',
                                name: 'build_c',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                id: '38',
                                name: 'build_b',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                id: '39',
                                name:
                                  'build_a_nlfjkdnlvskfnksvjknlfdjvlvnjdkjdf_nvjkenjkrlngjeknjkl',
                              },
                            ],
                          },
                          previousStageJobsOrNeeds: {
                            __typename: 'CiJobConnection',
                            nodes: [
                              {
                                __typename: 'CiBuildNeed',
                                id: '37',
                                name: 'build_c',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                id: '38',
                                name: 'build_b',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                id: '39',
                                name:
                                  'build_a_nlfjkdnlvskfnksvjknlfdjvlvnjdkjdf_nvjkenjkrlngjeknjkl',
                              },
                            ],
                          },
                        },
                      ],
                    },
                  },
                  {
                    __typename: 'CiGroup',
                    id: '40',
                    name: 'test_b',
                    size: 2,
                    status: {
                      __typename: 'DetailedStatus',
                      id: '41',
                      label: 'passed',
                      group: 'success',
                      icon: 'status_success',
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          id: '42',
                          kind: BUILD_KIND,
                          name: 'test_b 1/2',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            id: '43',
                            icon: 'status_success',
                            tooltip: 'passed',
                            label: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1489',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
                              id: '44',
                              buttonTitle: 'Retry this job',
                              icon: 'retry',
                              path: '/root/abcd-dag/-/jobs/1489/retry',
                              title: 'Retry',
                            },
                          },
                          needs: {
                            __typename: 'CiBuildNeedConnection',
                            nodes: [
                              {
                                __typename: 'CiBuildNeed',
                                id: '45',
                                name: 'build_d 3/3',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                id: '46',
                                name: 'build_d 2/3',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                id: '47',
                                name: 'build_d 1/3',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                id: '48',
                                name: 'build_b',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                id: '49',
                                name:
                                  'build_a_nlfjkdnlvskfnksvjknlfdjvlvnjdkjdf_nvjkenjkrlngjeknjkl',
                              },
                            ],
                          },
                          previousStageJobsOrNeeds: {
                            __typename: 'CiJobConnection',
                            nodes: [
                              {
                                __typename: 'CiBuildNeed',
                                id: '45',
                                name: 'build_d 3/3',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                id: '46',
                                name: 'build_d 2/3',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                id: '47',
                                name: 'build_d 1/3',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                id: '48',
                                name: 'build_b',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                id: '49',
                                name:
                                  'build_a_nlfjkdnlvskfnksvjknlfdjvlvnjdkjdf_nvjkenjkrlngjeknjkl',
                              },
                            ],
                          },
                        },
                        {
                          __typename: 'CiJob',
                          id: '67',
                          kind: BUILD_KIND,
                          name: 'test_b 2/2',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            id: '50',
                            icon: 'status_success',
                            tooltip: 'passed',
                            label: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1490',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
                              id: '51',
                              buttonTitle: 'Retry this job',
                              icon: 'retry',
                              path: '/root/abcd-dag/-/jobs/1490/retry',
                              title: 'Retry',
                            },
                          },
                          needs: {
                            __typename: 'CiBuildNeedConnection',
                            nodes: [
                              {
                                __typename: 'CiBuildNeed',
                                id: '52',
                                name: 'build_d 3/3',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                id: '53',
                                name: 'build_d 2/3',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                id: '54',
                                name: 'build_d 1/3',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                id: '55',
                                name: 'build_b',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                id: '56',
                                name:
                                  'build_a_nlfjkdnlvskfnksvjknlfdjvlvnjdkjdf_nvjkenjkrlngjeknjkl',
                              },
                            ],
                          },
                          previousStageJobsOrNeeds: {
                            __typename: 'CiJobConnection',
                            nodes: [
                              {
                                __typename: 'CiBuildNeed',
                                id: '52',
                                name: 'build_d 3/3',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                id: '53',
                                name: 'build_d 2/3',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                id: '54',
                                name: 'build_d 1/3',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                id: '55',
                                name: 'build_b',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                id: '56',
                                name:
                                  'build_a_nlfjkdnlvskfnksvjknlfdjvlvnjdkjdf_nvjkenjkrlngjeknjkl',
                              },
                            ],
                          },
                        },
                      ],
                    },
                  },
                  {
                    __typename: 'CiGroup',
                    name: 'test_c',
                    id: '57',
                    size: 1,
                    status: {
                      __typename: 'DetailedStatus',
                      id: '58',
                      label: null,
                      group: 'success',
                      icon: 'status_success',
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          id: '59',
                          kind: BUILD_KIND,
                          name: 'test_c',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            id: '60',
                            icon: 'status_success',
                            tooltip: null,
                            label: null,
                            hasDetails: true,
                            detailsPath: '/root/kinder-pipe/-/pipelines/154',
                            group: 'success',
                            action: null,
                          },
                          needs: {
                            __typename: 'CiBuildNeedConnection',
                            nodes: [],
                          },
                          previousStageJobsOrNeeds: {
                            __typename: 'CiJobConnection',
                            nodes: [],
                          },
                        },
                      ],
                    },
                  },
                  {
                    __typename: 'CiGroup',
                    id: '61',
                    name: 'test_d',
                    size: 1,
                    status: {
                      id: '62',
                      __typename: 'DetailedStatus',
                      label: null,
                      group: 'success',
                      icon: 'status_success',
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          id: '53',
                          kind: BUILD_KIND,
                          name: 'test_d',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            id: '64',
                            icon: 'status_success',
                            tooltip: null,
                            label: null,
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/pipelines/153',
                            group: 'success',
                            action: null,
                          },
                          needs: {
                            __typename: 'CiBuildNeedConnection',
                            nodes: [
                              {
                                __typename: 'CiBuildNeed',
                                id: '65',
                                name: 'build_b',
                              },
                            ],
                          },
                          previousStageJobsOrNeeds: {
                            __typename: 'CiJobConnection',
                            nodes: [
                              {
                                __typename: 'CiBuildNeed',
                                id: '65',
                                name: 'build_b',
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
          ],
        },
      },
    },
  },
};

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

export const triggerJobWithRetryAction = {
  ...triggerJob,
  status: {
    ...triggerJob.status,
    action: {
      icon: 'retry',
      title: RETRY_ACTION_TITLE,
      path: '/root/ci-mock/builds/4259/retry',
      method: 'post',
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
