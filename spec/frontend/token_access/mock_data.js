export const enabledJobTokenScope = {
  data: {
    project: {
      id: '1',
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
      id: '1',
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
      id: '1',
      ciJobTokenScope: {
        __typename: 'CiJobTokenScopeType',
        projects: {
          __typename: 'ProjectConnection',
          nodes: [
            {
              id: '2',
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

export const mockProjects = [
  {
    id: '1',
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
    id: '2',
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
    key: 'project',
    label: 'Project with access',
  },
  {
    key: 'namespace',
    label: 'Namespace',
  },
  {
    key: 'actions',
    label: '',
  },
];

export const inboundJobTokenScopeEnabledResponse = {
  data: {
    project: {
      id: '1',
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
      id: '1',
      ciCdSettings: {
        inboundJobTokenScopeEnabled: false,
        __typename: 'ProjectCiCdSetting',
      },
      __typename: 'Project',
    },
  },
};

export const inboundProjectsWithScopeResponse = {
  data: {
    project: {
      __typename: 'Project',
      id: '1',
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
              namespace: { id: 'gid://gitlab/Namespaces::UserNamespace/1', fullPath: 'root' },
            },
          ],
        },
      },
    },
  },
};

export const inboundAddProjectSuccessResponse = {
  data: {
    ciJobTokenScopeAddProject: {
      errors: [],
      __typename: 'CiJobTokenScopeAddProjectPayload',
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
