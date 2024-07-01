export const projectExclusionsMock = [
  { id: 1, name: 'project foo', type: 'project', icon: 'project', avatarUrl: 'project-foo.png' },
  { id: 2, name: 'project bar', type: 'project', icon: 'project', avatarUrl: 'project-bar.png' },
];

export const groupExclusionsMock = [
  { id: 1, name: 'group foo', type: 'group', icon: 'group', avatarUrl: 'group-foo.png' },
  { id: 2, name: 'group bar', type: 'group', icon: 'group', avatarUrl: 'group-bar.png' },
];

export const fetchExclusionsResponse = {
  data: {
    integrationExclusions: {
      nodes: [
        {
          group: null,
          project: {
            name: 'project foo',
            avatarUrl: 'foo.png',
            id: 'gid://gitlab/Project/1',
          },
        },
        {
          group: null,
          project: {
            name: 'project bar',
            avatarUrl: 'bar.png',
            id: 'gid://gitlab/Project/2',
          },
        },
        {
          project: null,
          group: {
            name: 'group foo',
            avatarUrl: 'foo.png',
            id: 'gid://gitlab/Group/2',
          },
        },
      ],
      pageInfo: {},
    },
  },
};

export const createExclusionMutationResponse = {
  data: {
    integrationExclusionCreate: {
      exclusions: [
        {
          project: {
            id: 'gid://gitlab/Project/97',
            name: 'approval-rules-25096c16cef9687d',
          },
        },
      ],
      errors: [],
    },
  },
};

export const deleteExclusionMutationResponse = {
  data: {
    integrationExclusionDelete: {
      exclusions: {
        project: {
          id: 'gid://gitlab/Project/97',
          name: 'approval-rules-25096c16cef9687d',
        },
      },
      errors: [],
    },
  },
};
