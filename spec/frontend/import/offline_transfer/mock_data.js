export const mockGroups = [
  {
    id: 'gid://glab/Group/1',
    fullName: 'Flight',
    fullPath: 'flight',
    description: 'Flight',
    avatarUrl: null,
    webUrl: 'http://gdko.test/flight',
    __typename: 'Group',
  },
  {
    id: 'gid://glab/Group/2',
    fullName: 'Space',
    fullPath: 'space',
    description: null,
    avatarUrl: '/a.png',
    webUrl: 'http://gdko.test/space',
    __typename: 'Group',
  },
  {
    id: 'gid://glab/Group/3',
    fullName: 'Sunny',
    fullPath: 'sunny',
    description: null,
    avatarUrl: '/avatar.png',
    webUrl: 'http://gdko.test/sunny',
    __typename: 'Group',
  },
];

export const mockGroupsResponse = {
  data: {
    groups: {
      nodes: mockGroups,
      pageInfo: {
        hasNextPage: false,
        hasPreviousPage: false,
        startCursor: null,
        endCursor: null,
        __typename: 'PageInfo',
      },
      __typename: 'GroupConnection',
    },
  },
};
