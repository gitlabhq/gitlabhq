export const runnersData = {
  data: {
    runners: {
      nodes: [
        {
          id: 'gid://gitlab/Ci::Runner/1',
          description: 'runner-1',
          runnerType: 'INSTANCE_TYPE',
          shortSha: '2P6oDVDm',
          version: '13.12.0',
          revision: '11223344',
          ipAddress: '127.0.0.1',
          active: true,
          locked: true,
          tagList: [],
          contactedAt: '2021-05-14T11:44:03Z',
          __typename: 'CiRunner',
        },
        {
          id: 'gid://gitlab/Ci::Runner/2',
          description: 'runner-2',
          runnerType: 'GROUP_TYPE',
          shortSha: 'dpSCAC31',
          version: '13.12.0',
          revision: '11223344',
          ipAddress: '127.0.0.1',
          active: true,
          locked: true,
          tagList: [],
          contactedAt: '2021-05-14T11:44:02Z',
          __typename: 'CiRunner',
        },
      ],
      pageInfo: {
        endCursor: 'GRAPHQL_END_CURSOR',
        startCursor: 'GRAPHQL_START_CURSOR',
        hasNextPage: true,
        hasPreviousPage: false,
        __typename: 'PageInfo',
      },
      __typename: 'CiRunnerConnection',
    },
  },
};
