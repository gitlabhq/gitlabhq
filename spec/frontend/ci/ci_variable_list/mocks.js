import {
  ADD_MUTATION_ACTION,
  DELETE_MUTATION_ACTION,
  UPDATE_MUTATION_ACTION,
  variableTypes,
  groupString,
  instanceString,
  projectString,
} from '~/ci/ci_variable_list/constants';

import addAdminVariable from '~/ci/ci_variable_list/graphql/mutations/admin_add_variable.mutation.graphql';
import deleteAdminVariable from '~/ci/ci_variable_list/graphql/mutations/admin_delete_variable.mutation.graphql';
import updateAdminVariable from '~/ci/ci_variable_list/graphql/mutations/admin_update_variable.mutation.graphql';
import addGroupVariable from '~/ci/ci_variable_list/graphql/mutations/group_add_variable.mutation.graphql';
import deleteGroupVariable from '~/ci/ci_variable_list/graphql/mutations/group_delete_variable.mutation.graphql';
import updateGroupVariable from '~/ci/ci_variable_list/graphql/mutations/group_update_variable.mutation.graphql';
import addProjectVariable from '~/ci/ci_variable_list/graphql/mutations/project_add_variable.mutation.graphql';
import deleteProjectVariable from '~/ci/ci_variable_list/graphql/mutations/project_delete_variable.mutation.graphql';
import updateProjectVariable from '~/ci/ci_variable_list/graphql/mutations/project_update_variable.mutation.graphql';

import getAdminVariables from '~/ci/ci_variable_list/graphql/queries/variables.query.graphql';
import getGroupVariables from '~/ci/ci_variable_list/graphql/queries/group_variables.query.graphql';
import { getProjectEnvironments } from '~/ci/common/private/ci_environments_dropdown';
import getProjectVariables from '~/ci/ci_variable_list/graphql/queries/project_variables.query.graphql';

export const devName = 'dev';
export const prodName = 'prod';

export const mockVariables = (kind) => {
  const withHidden = kind !== instanceString;
  return [
    {
      __typename: `Ci${kind}Variable`,
      id: 1,
      key: 'my-var',
      description: 'This variable has a description.',
      masked: false,
      ...(withHidden && { hidden: false }),
      protected: true,
      raw: false,
      value: 'variable_value',
      variableType: variableTypes.envType,
    },
    {
      __typename: `Ci${kind}Variable`,
      id: 2,
      key: 'secret',
      description: null,
      masked: true,
      ...(withHidden && { hidden: false }),
      protected: false,
      raw: true,
      value: 'another_value',
      variableType: variableTypes.fileType,
    },
    {
      __typename: `Ci${kind}Variable`,
      id: 3,
      key: 'hidden',
      description: null,
      masked: true,
      ...(withHidden && { hidden: true }),
      protected: false,
      raw: true,
      value: 'a_third_value',
      variableType: variableTypes.fileType,
    },
  ];
};

export const mockInheritedVariables = [
  {
    id: 'gid://gitlab/Ci::GroupVariable/120',
    key: 'INHERITED_VAR_1',
    variableType: 'ENV_VAR',
    description: null,
    environmentScope: '*',
    masked: true,
    hidden: false,
    protected: true,
    raw: false,
    groupName: 'group-name',
    groupCiCdSettingsPath: '/groups/group-name/-/settings/ci_cd',
    __typename: 'InheritedCiVariable',
  },
  {
    id: 'gid://gitlab/Ci::GroupVariable/121',
    key: 'INHERITED_VAR_2',
    variableType: 'ENV_VAR',
    description: 'This inherited variable has a description.',
    environmentScope: 'staging',
    masked: false,
    hidden: false,
    protected: false,
    raw: true,
    groupName: 'subgroup-name',
    groupCiCdSettingsPath: '/groups/group-name/subgroup-name/-/settings/ci_cd',
    __typename: 'InheritedCiVariable',
  },
  {
    id: 'gid://gitlab/Ci::GroupVariable/122',
    key: 'INHERITED_VAR_3',
    variableType: 'FILE',
    description: null,
    environmentScope: 'production',
    masked: false,
    hidden: false,
    protected: true,
    raw: true,
    groupName: 'subgroup-name',
    groupCiCdSettingsPath: '/groups/group-name/subgroup-name/-/settings/ci_cd',
    __typename: 'InheritedCiVariable',
  },
  {
    id: 'gid://gitlab/Ci::GroupVariable/123',
    key: 'INHERITED_VAR_4',
    variableType: 'ENV_VAR',
    description: null,
    environmentScope: 'production',
    masked: true,
    hidden: true,
    protected: true,
    raw: true,
    groupName: 'subgroup-name',
    groupCiCdSettingsPath: '/groups/group-name/subgroup-name/-/settings/ci_cd',
    __typename: 'InheritedCiVariable',
  },
];

export const mockVariablesWithScopes = (kind) =>
  mockVariables(kind).map((variable) => {
    return { ...variable, environmentScope: '*' };
  });

export const mockVariablesWithUniqueScopes = (kind) =>
  mockVariables(kind).map((variable) => {
    return { ...variable, environmentScope: variable.value };
  });

const createDefaultVars = ({ withScope = true, kind } = {}) => {
  let base = mockVariables(kind);

  if (withScope) {
    base = mockVariablesWithScopes(kind);
  }

  return {
    __typename: `Ci${kind}VariableConnection`,
    limit: 200,
    pageInfo: {
      startCursor: 'adsjsd12kldpsa',
      endCursor: 'adsjsd12kldpsa',
      hasPreviousPage: false,
      hasNextPage: true,
    },
    nodes: base,
  };
};

const defaultEnvs = {
  __typename: 'EnvironmentConnection',
  nodes: [
    {
      __typename: 'Environment',
      id: 1,
      name: prodName,
    },
    {
      __typename: 'Environment',
      id: 2,
      name: devName,
    },
  ],
};

export const mockEnvs = defaultEnvs.nodes;

export const mockProjectEnvironments = {
  data: {
    project: {
      __typename: 'Project',
      id: 1,
      environments: defaultEnvs,
    },
  },
};

export const mockProjectVariables = {
  data: {
    project: {
      __typename: 'Project',
      id: 1,
      ciVariables: createDefaultVars({ kind: projectString }),
    },
  },
};

export const mockGroupVariables = {
  data: {
    group: {
      __typename: 'Group',
      id: 1,
      ciVariables: createDefaultVars({ kind: groupString }),
    },
  },
};

export const mockAdminVariables = {
  data: {
    ciVariables: createDefaultVars({ withScope: false, kind: instanceString }),
  },
};

export const newVariable = {
  id: 3,
  environmentScope: 'new',
  key: 'AWS_RANDOM_THING',
  masked: true,
  protected: false,
  value: 'devops',
  variableType: variableTypes.variableType,
};

export const createProjectProps = () => {
  return {
    componentName: 'ProjectVariable',
    entity: 'project',
    fullPath: '/namespace/project/',
    id: 'gid://gitlab/Project/20',
    mutationData: {
      [ADD_MUTATION_ACTION]: addProjectVariable,
      [UPDATE_MUTATION_ACTION]: updateProjectVariable,
      [DELETE_MUTATION_ACTION]: deleteProjectVariable,
    },
    queryData: {
      ciVariables: {
        lookup: (data) => data?.project?.ciVariables,
        query: getProjectVariables,
      },
      environments: {
        lookup: (data) => data?.project?.environments,
        query: getProjectEnvironments,
      },
    },
  };
};

export const createGroupProps = () => {
  return {
    componentName: 'GroupVariable',
    entity: 'group',
    fullPath: '/my-group',
    id: 'gid://gitlab/Group/20',
    mutationData: {
      [ADD_MUTATION_ACTION]: addGroupVariable,
      [UPDATE_MUTATION_ACTION]: updateGroupVariable,
      [DELETE_MUTATION_ACTION]: deleteGroupVariable,
    },
    queryData: {
      ciVariables: {
        lookup: (data) => data?.group?.ciVariables,
        query: getGroupVariables,
      },
    },
  };
};

export const createInstanceProps = () => {
  return {
    componentName: 'InstanceVariable',
    entity: '',
    mutationData: {
      [ADD_MUTATION_ACTION]: addAdminVariable,
      [UPDATE_MUTATION_ACTION]: updateAdminVariable,
      [DELETE_MUTATION_ACTION]: deleteAdminVariable,
    },
    queryData: {
      ciVariables: {
        lookup: (data) => data?.ciVariables,
        query: getAdminVariables,
      },
    },
  };
};

export const createGroupProvide = () => ({
  isGroup: true,
  isProject: false,
});

export const createProjectProvide = () => ({
  isGroup: false,
  isProject: true,
});
