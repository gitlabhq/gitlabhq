import { unwrapPipelineData } from '~/pipelines/components/graph/utils';

export const mockPipelineResponse = {
  data: {
    project: {
      __typename: 'Project',
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
              name: 'build',
              status: {
                __typename: 'DetailedStatus',
                action: null,
              },
              groups: {
                __typename: 'CiGroupConnection',
                nodes: [
                  {
                    __typename: 'CiGroup',
                    name: 'build_a_nlfjkdnlvskfnksvjknlfdjvlvnjdkjdf_nvjkenjkrlngjeknjkl',
                    size: 1,
                    status: {
                      __typename: 'DetailedStatus',
                      label: 'passed',
                      group: 'success',
                      icon: 'status_success',
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          name: 'build_a_nlfjkdnlvskfnksvjknlfdjvlvnjdkjdf_nvjkenjkrlngjeknjkl',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1482',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
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
                        },
                      ],
                    },
                  },
                  {
                    __typename: 'CiGroup',
                    name: 'build_b',
                    size: 1,
                    status: {
                      __typename: 'DetailedStatus',
                      label: 'passed',
                      group: 'success',
                      icon: 'status_success',
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          name: 'build_b',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1515',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
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
                        },
                      ],
                    },
                  },
                  {
                    __typename: 'CiGroup',
                    name: 'build_c',
                    size: 1,
                    status: {
                      __typename: 'DetailedStatus',
                      label: 'passed',
                      group: 'success',
                      icon: 'status_success',
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          name: 'build_c',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1484',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
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
                        },
                      ],
                    },
                  },
                  {
                    __typename: 'CiGroup',
                    name: 'build_d',
                    size: 3,
                    status: {
                      __typename: 'DetailedStatus',
                      label: 'passed',
                      group: 'success',
                      icon: 'status_success',
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          name: 'build_d 1/3',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1485',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
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
                        },
                        {
                          __typename: 'CiJob',
                          name: 'build_d 2/3',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1486',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
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
                        },
                        {
                          __typename: 'CiJob',
                          name: 'build_d 3/3',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1487',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
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
                        },
                      ],
                    },
                  },
                ],
              },
            },
            {
              __typename: 'CiStage',
              name: 'test',
              status: {
                __typename: 'DetailedStatus',
                action: null,
              },
              groups: {
                __typename: 'CiGroupConnection',
                nodes: [
                  {
                    __typename: 'CiGroup',
                    name: 'test_a',
                    size: 1,
                    status: {
                      __typename: 'DetailedStatus',
                      label: 'passed',
                      group: 'success',
                      icon: 'status_success',
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          name: 'test_a',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1514',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
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
                                name: 'build_c',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                name: 'build_b',
                              },
                              {
                                __typename: 'CiBuildNeed',
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
                    name: 'test_b',
                    size: 2,
                    status: {
                      __typename: 'DetailedStatus',
                      label: 'passed',
                      group: 'success',
                      icon: 'status_success',
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          name: 'test_b 1/2',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1489',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
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
                                name: 'build_d 3/3',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                name: 'build_d 2/3',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                name: 'build_d 1/3',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                name: 'build_b',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                name:
                                  'build_a_nlfjkdnlvskfnksvjknlfdjvlvnjdkjdf_nvjkenjkrlngjeknjkl',
                              },
                            ],
                          },
                        },
                        {
                          __typename: 'CiJob',
                          name: 'test_b 2/2',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1490',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
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
                                name: 'build_d 3/3',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                name: 'build_d 2/3',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                name: 'build_d 1/3',
                              },
                              {
                                __typename: 'CiBuildNeed',
                                name: 'build_b',
                              },
                              {
                                __typename: 'CiBuildNeed',
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
                    size: 1,
                    status: {
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
                          name: 'test_c',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: null,
                            hasDetails: true,
                            detailsPath: '/root/kinder-pipe/-/pipelines/154',
                            group: 'success',
                            action: null,
                          },
                          needs: {
                            __typename: 'CiBuildNeedConnection',
                            nodes: [],
                          },
                        },
                      ],
                    },
                  },
                  {
                    __typename: 'CiGroup',
                    name: 'test_d',
                    size: 1,
                    status: {
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
                          name: 'test_d',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: null,
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
      status: {
        group: 'success',
        label: 'passed',
        icon: 'status_success',
        __typename: 'DetailedStatus',
      },
      sourceJob: {
        name: 'test_c',
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
      status: {
        group: 'success',
        label: 'passed',
        icon: 'status_success',
        __typename: 'DetailedStatus',
      },
      sourceJob: {
        name: 'test_d',
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
  status: {
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
          __typename: 'PipelineConnection',
          nodes: [],
        },
        upstream: {
          id: 'gid://gitlab/Ci::Pipeline/174',
          iid: '37',
          path: '/root/elemenohpee/-/pipelines/174',
          __typename: 'Pipeline',
          status: {
            __typename: 'DetailedStatus',
            group: 'success',
            label: 'passed',
            icon: 'status_success',
          },
          sourceJob: {
            name: 'test_c',
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
              status: {
                action: null,
                __typename: 'DetailedStatus',
              },
              groups: {
                __typename: 'CiGroupConnection',
                nodes: [
                  {
                    __typename: 'CiGroup',
                    status: {
                      __typename: 'DetailedStatus',
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
                          name: 'build_n',
                          scheduledAt: null,
                          needs: {
                            __typename: 'CiBuildNeedConnection',
                            nodes: [],
                          },
                          status: {
                            __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/elemenohpee/-/jobs/1662',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
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
