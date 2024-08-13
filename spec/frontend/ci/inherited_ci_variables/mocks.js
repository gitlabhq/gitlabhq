export const mockInheritedCiVariables = ({ withNextPage = false } = {}) => ({
  data: {
    project: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/38',
      inheritedCiVariables: {
        __typename: `InheritedCiVariableConnection`,
        pageInfo: {
          startCursor: 'adsjsd12kldpsa',
          endCursor: 'adsjsd12kldpsa',
          hasPreviousPage: withNextPage,
          hasNextPage: withNextPage,
          __typename: 'PageInfo',
        },
        nodes: [
          {
            __typename: `InheritedCiVariable`,
            id: 'gid://gitlab/Ci::GroupVariable/1',
            description: 'This will be inherited by projects',
            environmentScope: '*',
            groupName: 'group_abc',
            groupCiCdSettingsPath: '/groups/group_abc/-/settings/ci_cd',
            key: 'GROUP_VAR',
            masked: false,
            hidden: false,
            protected: true,
            raw: false,
            variableType: 'ENV_VAR',
          },
          {
            __typename: `InheritedCiVariable`,
            id: 'gid://gitlab/Ci::GroupVariable/2',
            description: null,
            environmentScope: '*',
            groupName: 'subgroup_xyz',
            groupCiCdSettingsPath: '/groups/group_abc/subgroup_xyz/-/settings/ci_cd',
            key: 'SUB_GROUP_VAR',
            masked: true,
            hidden: false,
            protected: false,
            raw: true,
            variableType: 'ENV_VAR',
          },
        ],
      },
    },
  },
});
