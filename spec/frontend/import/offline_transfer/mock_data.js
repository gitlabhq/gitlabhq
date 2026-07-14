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

export const mockGroupsPage2 = [
  {
    id: 'gid://glab/Group/4',
    fullName: 'Comet',
    fullPath: 'comet',
    description: null,
    avatarUrl: null,
    webUrl: 'http://gdko.test/comet',
    __typename: 'Group',
  },
  {
    id: 'gid://glab/Group/5',
    fullName: 'Nova',
    fullPath: 'nova',
    description: null,
    avatarUrl: null,
    webUrl: 'http://gdko.test/nova',
    __typename: 'Group',
  },
  {
    id: 'gid://glab/Group/6',
    fullName: 'Orbit',
    fullPath: 'orbit',
    description: null,
    avatarUrl: null,
    webUrl: 'http://gdko.test/orbit',
    __typename: 'Group',
  },
];

// Page 1 of a two-page set — advertises a next page so next/prev can be exercised.
export const mockGroupsPage1Response = {
  data: {
    groups: {
      nodes: mockGroups,
      pageInfo: {
        hasNextPage: true,
        hasPreviousPage: false,
        startCursor: null,
        endCursor: 'page-1-end-cursor',
        __typename: 'PageInfo',
      },
      __typename: 'GroupConnection',
    },
  },
};

export const mockGroupsPage2Response = {
  data: {
    groups: {
      nodes: mockGroupsPage2,
      pageInfo: {
        hasNextPage: false,
        hasPreviousPage: true,
        startCursor: 'page-2-start-cursor',
        endCursor: 'page-2-end-cursor',
        __typename: 'PageInfo',
      },
      __typename: 'GroupConnection',
    },
  },
};
