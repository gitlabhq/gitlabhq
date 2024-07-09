export const enabledJobTokenScope = {
  data: {
    project: {
      id: 1,
      ciCdSettings: {
        jobTokenScopeEnabled: true,
        __typename: 'ProjectCiCdSetting',
      },
      __typename: 'Project',
    },
  },
};

export const disabledJobTokenScope = {
  data: {
    project: {
      id: 1,
      ciCdSettings: {
        jobTokenScopeEnabled: false,
        __typename: 'ProjectCiCdSetting',
      },
      __typename: 'Project',
    },
  },
};

export const projectsWithScope = {
  data: {
    project: {
      __typename: 'Project',
      id: 1,
      ciJobTokenScope: {
        __typename: 'CiJobTokenScopeType',
        projects: {
          __typename: 'ProjectConnection',
          nodes: [
            {
              id: 2,
              fullPath: 'root/332268-test',
              name: 'root/332268-test',
              namespace: {
                id: '1234',
                fullPath: 'root',
              },
            },
          ],
        },
      },
    },
  },
};

export const addProjectSuccess = {
  data: {
    ciJobTokenScopeAddProject: {
      errors: [],
      __typename: 'CiJobTokenScopeAddProjectPayload',
    },
  },
};

export const removeProjectSuccess = {
  data: {
    ciJobTokenScopeRemoveProject: {
      errors: [],
      __typename: 'CiJobTokenScopeRemoveProjectPayload',
    },
  },
};

export const updateScopeSuccess = {
  data: {
    projectCiCdSettingsUpdate: {
      ciCdSettings: {
        jobTokenScopeEnabled: false,
        __typename: 'ProjectCiCdSetting',
      },
      errors: [],
      __typename: 'ProjectCiCdSettingsUpdatePayload',
    },
  },
};

export const mockGroups = [
  {
    id: 1,
    name: 'some-group',
    fullPath: 'some-group',
    __typename: 'Group',
  },
  {
    id: 2,
    name: 'another-group',
    fullPath: 'another-group',
    __typename: 'Group',
  },
  {
    id: 3,
    name: 'a-sub-group',
    fullPath: 'another-group/a-sub-group',
    __typename: 'Group',
  },
];

export const mockProjects = [
  {
    id: 1,
    name: 'merge-train-stuff',
    namespace: {
      id: '1235',
      fullPath: 'root',
    },
    fullPath: 'root/merge-train-stuff',
    isLocked: false,
    __typename: 'Project',
  },
  {
    id: 2,
    name: 'ci-project',
    namespace: {
      id: '1236',
      fullPath: 'root',
    },
    fullPath: 'root/ci-project',
    isLocked: true,
    __typename: 'Project',
  },
];

export const mockFields = [
  {
    key: 'fullPath',
    label: '',
  },
  {
    key: 'actions',
    label: '',
  },
];

export const inboundJobTokenScopeEnabledResponse = {
  data: {
    project: {
      id: 1,
      ciCdSettings: {
        inboundJobTokenScopeEnabled: true,
        __typename: 'ProjectCiCdSetting',
      },
      __typename: 'Project',
    },
  },
};

export const inboundJobTokenScopeDisabledResponse = {
  data: {
    project: {
      id: 1,
      ciCdSettings: {
        inboundJobTokenScopeEnabled: false,
        __typename: 'ProjectCiCdSetting',
      },
      __typename: 'Project',
    },
  },
};

export const inboundGroupsAndProjectsWithScopeResponse = {
  data: {
    project: {
      __typename: 'Project',
      id: 1,
      ciJobTokenScope: {
        __typename: 'CiJobTokenScopeType',
        inboundAllowlist: {
          __typename: 'ProjectConnection',
          nodes: [
            {
              __typename: 'Project',
              fullPath: 'root/ci-project',
              id: 'gid://gitlab/Project/23',
              name: 'ci-project',
              avatarUrl: '',
            },
          ],
        },
        groupsAllowlist: {
          __typename: 'GroupConnection',
          nodes: [
            {
              __typename: 'Group',
              fullPath: 'root/ci-group',
              id: 'gid://gitlab/Group/45',
              name: 'ci-group',
              avatarUrl: '',
            },
          ],
        },
      },
    },
  },
};

export const inboundGroupsAndProjectsWithScopeResponseWithAddedItem = {
  data: {
    project: {
      ...inboundGroupsAndProjectsWithScopeResponse.data.project,
      ciJobTokenScope: {
        inboundAllowlist: {
          nodes: [
            ...inboundGroupsAndProjectsWithScopeResponse.data.project.ciJobTokenScope
              .inboundAllowlist.nodes,
            {
              __typename: 'Project',
              fullPath: 'root/test',
              id: 'gid://gitlab/Project/25',
              name: 'test',
              avatarUrl: '',
            },
          ],
        },
        groupsAllowlist: {
          nodes: [
            ...inboundGroupsAndProjectsWithScopeResponse.data.project.ciJobTokenScope
              .groupsAllowlist.nodes,
            {
              __typename: 'Group',
              fullPath: 'gitlab-org',
              id: 'gid://gitlab/Group/49',
              name: 'gitlab-org',
              avatarUrl: '',
            },
          ],
        },
      },
    },
  },
};

export const getGroupsAndProjectsResponse = {
  data: {
    groups: {
      nodes: [
        { id: 1, name: 'gitlab-org', avatarUrl: '', fullPath: 'gitlab-org' },
        { id: 2, name: 'ci-group', avatarUrl: '', fullPath: 'root/ci-group' },
      ],
    },
    projects: {
      nodes: [
        { id: 1, name: 'gitlab', avatarUrl: '', fullPath: 'gitlab-org/gitlab' },
        { id: 2, name: 'ci-project', avatarUrl: '', fullPath: 'root/ci-project' },
      ],
    },
  },
};

export const inboundAddGroupOrProjectSuccessResponse = {
  data: {
    ciJobTokenScopeAddProject: {
      errors: [],
      __typename: 'CiJobTokenScopeAddProjectPayload',
    },
  },
};

export const inboundRemoveGroupSuccess = {
  data: {
    ciJobTokenScopeRemoveProject: {
      errors: [],
      __typename: 'CiJobTokenScopeRemoveGroupPayload',
    },
  },
};

export const inboundRemoveProjectSuccess = {
  data: {
    ciJobTokenScopeRemoveProject: {
      errors: [],
      __typename: 'CiJobTokenScopeRemoveProjectPayload',
    },
  },
};

export const inboundUpdateScopeSuccessResponse = {
  data: {
    projectCiCdSettingsUpdate: {
      ciCdSettings: {
        inboundJobTokenScopeEnabled: false,
        __typename: 'ProjectCiCdSetting',
      },
      errors: [],
      __typename: 'ProjectCiCdSettingsUpdatePayload',
    },
  },
};

export const mockPermissionsQueryResponse = (pushRepositoryForJobTokenAllowed = false) => ({
  data: {
    project: {
      id: 'gid://gitlab/Project/20',
      name: 'ops',
      ciCdSettings: {
        pushRepositoryForJobTokenAllowed,
        __typename: 'ProjectCiCdSetting',
      },
      __typename: 'Project',
    },
  },
});

export const mockPermissionsMutationResponse = ({
  pushRepositoryForJobTokenAllowed = true,
  errors = [],
} = {}) => ({
  data: {
    projectCiCdSettingsUpdate: {
      ciCdSettings: {
        pushRepositoryForJobTokenAllowed,
        __typename: 'ProjectCiCdSetting',
      },
      errors,
      __typename: 'Project',
    },
  },
});
