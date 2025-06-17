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
    defaultPermissions: false,
    jobTokenPolicies: ['READ_JOBS', 'ADMIN_DEPLOYMENTS'],
    autopopulated: true,
    __typename: 'CiJobTokenAccessibleGroup',
  },
  {
    id: 2,
    name: 'another-group',
    fullPath: 'another-group',
    webUrl: 'http://localhost/another-group',
    defaultPermissions: true,
    jobTokenPolicies: [],
    autopopulated: true,
    __typename: 'CiJobTokenAccessibleGroup',
  },
  {
    id: 3,
    name: 'a-sub-group',
    fullPath: 'another-group/a-sub-group',
    webUrl: 'http://localhost/a-sub-group',
    defaultPermissions: false,
    jobTokenPolicies: [],
    autopopulated: false,
    __typename: 'CiJobTokenAccessibleGroup',
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
    defaultPermissions: false,
    jobTokenPolicies: ['READ_JOBS'],
    isLocked: false,
    autopopulated: true,
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
    defaultPermissions: true,
    jobTokenPolicies: [],
    isLocked: true,
    autopopulated: false,
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

export const inboundGroupsAndProjectsWithScopeResponse = (hasAutopopulatedEntries = true) => ({
  data: {
    project: {
      __typename: 'Project',
      id: 1,
      ciJobTokenScope: {
        __typename: 'CiJobTokenScopeType',
        inboundAllowlist: {
          __typename: 'CiJobTokenAccessibleProjectConnection',
          nodes: [
            {
              __typename: 'CiJobTokenAccessibleProject',
              fullPath: 'root/ci-project',
              id: 'gid://gitlab/Project/23',
              name: 'ci-project',
              avatarUrl: '',
              webUrl: 'http://localhost/root/ci-project',
            },
          ],
        },
        groupsAllowlist: {
          __typename: 'CiJobTokenAccessibleGroupConnection',
          nodes: [
            {
              __typename: 'CiJobTokenAccessibleGroup',
              fullPath: 'root/ci-group',
              id: 'gid://gitlab/Group/45',
              name: 'ci-group',
              avatarUrl: '',
              webUrl: 'http://localhost/root/ci-group',
            },
          ],
        },
        groupAllowlistAutopopulatedIds: hasAutopopulatedEntries ? ['gid://gitlab/Group/45'] : [],
        inboundAllowlistAutopopulatedIds: hasAutopopulatedEntries
          ? ['gid://gitlab/Project/23']
          : [],
      },
    },
  },
});

export const getSaveNamespaceHandler = (error) =>
  jest.fn().mockResolvedValue({
    data: { saveNamespace: { errors: error ? [error] : [] } },
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

export const mockAuthLogsCountResponse = (count) => ({
  data: {
    project: {
      id: 'gid://gitlab/Project/26',
      __typename: 'Project',
      ciJobTokenAuthLogs: {
        __typename: 'CiJobTokenAuthLogConnection',
        count,
      },
    },
  },
});

export const mockCiJobTokenScopeAllowlistResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/26',
      name: 'my-repo',
      fullPath: 'root/my-repo',
      avatarUrl: '',
      webUrl: 'http://localhost/root/my-repo',
      ciJobTokenScopeAllowlist: {
        groupsAllowlist: {
          nodes: [
            {
              defaultPermissions: true,
              jobTokenPolicies: [],
              autopopulated: true,
              target: {
                id: 'gid://gitlab/Group/4',
                name: 'zed',
                fullPath: 'zed',
                avatarUrl: '',
                webUrl: 'http://localhost/zed',
                __typename: 'CiJobTokenAccessibleGroup',
              },
              __typename: 'CiJobTokenScopeAllowlistEntry',
            },
          ],
        },
        projectsAllowlist: {
          nodes: [
            {
              defaultPermissions: true,
              jobTokenPolicies: [],
              autopopulated: true,
              target: {
                id: 'gid://gitlab/Project/23',
                name: 'your-repo',
                fullPath: 'root/your-repo',
                avatarUrl: '',
                webUrl: 'http://localhost/root/your-repo',
                __typename: 'CiJobTokenAccessibleProject',
              },
              __typename: 'CiJobTokenScopeAllowlistEntry',
            },
            {
              defaultPermissions: true,
              jobTokenPolicies: [],
              autopopulated: true,
              target: {
                id: 'gid://gitlab/Project/14',
                name: 'abc123',
                fullPath: 'abc/123',
                avatarUrl: '',
                webUrl: 'http://localhost/abc/123',
                __typename: 'CiJobTokenAccessibleProject',
              },
              __typename: 'CiJobTokenScopeAllowlistEntry',
            },
          ],
        },
      },
    },
  },
};

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
              __typename: 'CiJobTokenAccessibleProject',
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

export const mockAutopopulateAllowlistResponse = ({ errorMessage } = {}) => ({
  data: {
    ciJobTokenScopeAutopopulateAllowlist: {
      status: 'complete',
      errors: errorMessage ? [{ message: errorMessage }] : [],
      __typename: 'CiJobTokenScopeAutopopulateAllowlistPayload',
    },
  },
});

export const mockRemoveAutopopulatedEntriesResponse = ({ errorMessage } = {}) => ({
  data: {
    ciJobTokenScopeClearAllowlistAutopopulations: {
      status: 'complete',
      errors: errorMessage ? [{ message: errorMessage }] : [],
      __typename: 'CiJobTokenScopeClearAllowlistAutopopulationsPayload',
    },
  },
});
