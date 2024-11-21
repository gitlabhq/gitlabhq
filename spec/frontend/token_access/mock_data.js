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
              webUrl: 'http://localhost/root/332268-test',
              avatarUrl: 'http://localhost/avatar.png',
            },
          ],
        },
      },
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
    webUrl: 'http://localhost/some-group',
    __typename: 'Group',
  },
  {
    id: 2,
    name: 'another-group',
    fullPath: 'another-group',
    webUrl: 'http://localhost/another-group',
    __typename: 'Group',
  },
  {
    id: 3,
    name: 'a-sub-group',
    fullPath: 'another-group/a-sub-group',
    webUrl: 'http://localhost/a-sub-group',
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
    webUrl: 'http://localhost/root/merge-train-stuff',
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
    webUrl: 'http://localhost/root/ci-project',
    isLocked: true,
    __typename: 'Project',
  },
];

export const inboundJobTokenScopeEnabledResponse = {
  data: {
    project: {
      id: 1,
      name: 'Test project',
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
      name: 'Test project',
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
              webUrl: 'http://localhost/root/ci-project',
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
              webUrl: 'http://localhost/root/ci-group',
            },
          ],
        },
      },
    },
  },
};

export const getAddNamespaceHandler = (error) =>
  jest.fn().mockResolvedValue({
    data: { ciJobTokenScopeAddGroupOrProject: { errors: error ? [error] : [] } },
  });

export const inboundRemoveNamespaceSuccess = {
  data: { removeNamespace: { errors: [] } },
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

export const mockAuthLogsResponse = (hasNextPage = false) => ({
  data: {
    project: {
      id: 'gid://gitlab/Project/26',
      __typename: 'Project',
      ciJobTokenAuthLogs: {
        __typename: 'CiJobTokenAuthLogConnection',
        count: 1,
        nodes: [
          {
            __typename: 'CiJobTokenAuthLog',
            lastAuthorizedAt: '2024-10-25',
            originProject: {
              __typename: 'Project',
              fullPath: 'root/project-that-triggers-external-pipeline',
              path: 'project-that-triggers-external-pipeline',
              avatarUrl: null,
              name: 'project-that-triggers-external-pipeline',
              id: 'gid://gitlab/Project/26',
            },
          },
        ],
        pageInfo: {
          __typename: 'PageInfo',
          endCursor: 'eyJpZCI6IjEifQ',
          hasNextPage,
        },
      },
    },
  },
});
