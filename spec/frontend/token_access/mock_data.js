export const enabledJobTokenScope = {
  data: {
    project: {
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
      ciCdSettings: {
        jobTokenScopeEnabled: false,
        __typename: 'ProjectCiCdSetting',
      },
      __typename: 'Project',
    },
  },
};

export const updateJobTokenScope = {
  data: {
    ciCdSettingsUpdate: {
      ciCdSettings: {
        jobTokenScopeEnabled: true,
        __typename: 'ProjectCiCdSetting',
      },
      errors: [],
      __typename: 'CiCdSettingsUpdatePayload',
    },
  },
};

export const projectsWithScope = {
  data: {
    project: {
      __typename: 'Project',
      ciJobTokenScope: {
        __typename: 'CiJobTokenScopeType',
        projects: {
          __typename: 'ProjectConnection',
          nodes: [
            {
              fullPath: 'root/332268-test',
              name: 'root/332268-test',
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

export const mockProjects = [
  {
    name: 'merge-train-stuff',
    fullPath: 'root/merge-train-stuff',
    isLocked: false,
    __typename: 'Project',
  },
  { name: 'ci-project', fullPath: 'root/ci-project', isLocked: true, __typename: 'Project' },
];
