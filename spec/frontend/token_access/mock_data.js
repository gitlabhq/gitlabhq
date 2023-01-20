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
    ciCdSettingsUpdate: {
      ciCdSettings: {
        jobTokenScopeEnabled: false,
        __typename: 'ProjectCiCdSetting',
      },
      errors: [],
      __typename: 'CiCdSettingsUpdatePayload',
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

export const optInJwtQueryResponse = (optInJwt) => ({
  data: {
    project: {
      id: '1',
      ciCdSettings: {
        optInJwt,
        __typename: 'ProjectCiCdSetting',
      },
      __typename: 'Project',
    },
  },
});

export const optInJwtMutationResponse = (optInJwt) => ({
  data: {
    ciCdSettingsUpdate: {
      ciCdSettings: {
        optInJwt,
        __typename: 'ProjectCiCdSetting',
      },
      errors: [],
      __typename: 'CiCdSettingsUpdatePayload',
    },
  },
});
