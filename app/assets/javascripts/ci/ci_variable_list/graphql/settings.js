import axios from 'axios';
import { orderBy } from 'lodash';
import {
  convertObjectPropsToCamelCase,
  convertObjectPropsToSnakeCase,
} from '~/lib/utils/common_utils';
import { TYPENAME_CI_VARIABLE, TYPENAME_GROUP, TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import {
  groupString,
  instanceString,
  projectString,
  visibilityToAttributesMap,
} from '../constants';
import getProjectVariables from './queries/project_variables.query.graphql';
import getGroupVariables from './queries/group_variables.query.graphql';
import getAdminVariables from './queries/variables.query.graphql';

const prepareVariableForApi = ({ variable, destroy = false }) => {
  return {
    ...convertObjectPropsToSnakeCase(variable),
    id: getIdFromGraphQLId(variable?.id),
    variable_type: variable.variableType.toLowerCase(),
    secret_value: variable.value,
    ...visibilityToAttributesMap[variable.visibility],
    _destroy: destroy,
  };
};

const mapVariableTypes = (variables = [], kind) => {
  return variables.map((ciVar) => {
    return {
      __typename: `Ci${kind}Variable`,
      ...convertObjectPropsToCamelCase(ciVar),
      id: convertToGraphQLId(TYPENAME_CI_VARIABLE, ciVar.id),
      variableType: ciVar.variable_type ? ciVar.variable_type.toUpperCase() : ciVar.variableType,
    };
  });
};

const sortVariables = (variables = []) => orderBy(variables, 'key', 'asc');

const prepareProjectGraphQLResponse = ({ data, id, limit, errors = [] }) => {
  return {
    errors,
    project: {
      __typename: TYPENAME_PROJECT,
      id: convertToGraphQLId(TYPENAME_PROJECT, id),
      ciVariables: {
        __typename: 'CiProjectVariableConnection',
        limit,
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: '',
          endCursor: '',
        },
        nodes: sortVariables(mapVariableTypes(data.variables, projectString)),
      },
    },
  };
};

const prepareGroupGraphQLResponse = ({ data, id, limit, errors = [] }) => {
  return {
    errors,
    group: {
      __typename: TYPENAME_GROUP,
      id: convertToGraphQLId(TYPENAME_GROUP, id),
      ciVariables: {
        __typename: `CiGroupVariableConnection`,
        limit,
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: '',
          endCursor: '',
        },
        nodes: sortVariables(mapVariableTypes(data.variables, groupString)),
      },
    },
  };
};

const prepareAdminGraphQLResponse = ({ data, errors = [] }) => {
  return {
    errors,
    ciVariables: {
      __typename: `Ci${instanceString}VariableConnection`,
      pageInfo: {
        __typename: 'PageInfo',
        hasNextPage: false,
        hasPreviousPage: false,
        startCursor: '',
        endCursor: '',
      },
      nodes: mapVariableTypes(data.variables, instanceString),
    },
  };
};

async function callProjectEndpoint({ endpoint, fullPath, variable, id, cache, destroy = false }) {
  try {
    const { data } = await axios.patch(endpoint, {
      variables_attributes: [prepareVariableForApi({ variable, destroy })],
    });
    const { limit } = cache.readQuery({ query: getProjectVariables, variables: { fullPath } })
      .project.ciVariables;

    const graphqlData = prepareProjectGraphQLResponse({ data, id, limit });

    cache.writeQuery({
      query: getProjectVariables,
      variables: {
        fullPath,
        after: null,
      },
      data: graphqlData,
    });
    return graphqlData;
  } catch (e) {
    return prepareProjectGraphQLResponse({
      data: cache.readQuery({ query: getProjectVariables, variables: { fullPath } }),
      id,
      errors: [...e.response.data],
    });
  }
}

const callGroupEndpoint = async ({ endpoint, fullPath, variable, id, cache, destroy = false }) => {
  try {
    const { data } = await axios.patch(endpoint, {
      variables_attributes: [prepareVariableForApi({ variable, destroy })],
    });
    const { limit } = cache.readQuery({ query: getGroupVariables, variables: { fullPath } }).group
      .ciVariables;

    const graphqlData = prepareGroupGraphQLResponse({ data, id, limit });

    cache.writeQuery({
      query: getGroupVariables,
      data: graphqlData,
    });

    return graphqlData;
  } catch (e) {
    return prepareGroupGraphQLResponse({
      data: cache.readQuery({ query: getGroupVariables, variables: { fullPath } }),
      id,
      errors: [...e.response.data],
    });
  }
};

const callAdminEndpoint = async ({ endpoint, variable, cache, destroy = false }) => {
  try {
    const { data } = await axios.patch(endpoint, {
      variables_attributes: [prepareVariableForApi({ variable, destroy })],
    });

    const graphqlData = prepareAdminGraphQLResponse({ data });

    cache.writeQuery({
      query: getAdminVariables,
      data: graphqlData,
    });

    return graphqlData;
  } catch (e) {
    return prepareAdminGraphQLResponse({
      data: cache.readQuery({ query: getAdminVariables }),
      errors: [...e.response.data],
    });
  }
};

export const resolvers = {
  Mutation: {
    addProjectVariable: async (_, { endpoint, fullPath, variable, id }, { cache }) => {
      return callProjectEndpoint({ endpoint, fullPath, variable, id, cache });
    },
    updateProjectVariable: async (_, { endpoint, fullPath, variable, id }, { cache }) => {
      return callProjectEndpoint({ endpoint, fullPath, variable, id, cache });
    },
    deleteProjectVariable: async (_, { endpoint, fullPath, variable, id }, { cache }) => {
      return callProjectEndpoint({ endpoint, fullPath, variable, id, cache, destroy: true });
    },
    addGroupVariable: async (_, { endpoint, fullPath, variable, id }, { cache }) => {
      return callGroupEndpoint({ endpoint, fullPath, variable, id, cache });
    },
    updateGroupVariable: async (_, { endpoint, fullPath, variable, id }, { cache }) => {
      return callGroupEndpoint({ endpoint, fullPath, variable, id, cache });
    },
    deleteGroupVariable: async (_, { endpoint, fullPath, variable, id }, { cache }) => {
      return callGroupEndpoint({ endpoint, fullPath, variable, id, cache, destroy: true });
    },
    addAdminVariable: async (_, { endpoint, variable }, { cache }) => {
      return callAdminEndpoint({ endpoint, variable, cache });
    },
    updateAdminVariable: async (_, { endpoint, variable }, { cache }) => {
      return callAdminEndpoint({ endpoint, variable, cache });
    },
    deleteAdminVariable: async (_, { endpoint, variable }, { cache }) => {
      return callAdminEndpoint({ endpoint, variable, cache, destroy: true });
    },
  },
};

export const mergeVariables = (existing, incoming, { args }) => {
  if (!existing || !args?.after) {
    return incoming;
  }

  const { nodes, ...rest } = incoming;
  const result = rest;
  result.nodes = [...existing.nodes, ...nodes];

  return result;
};

export const mergeOnlyIncomings = (_, incoming) => {
  return incoming;
};

export const generateCacheConfig = (isVariablePagesEnabled = false) => {
  const merge = isVariablePagesEnabled ? mergeOnlyIncomings : mergeVariables;
  return {
    cacheConfig: {
      typePolicies: {
        Query: {
          fields: {
            ciVariables: {
              keyArgs: false,
              merge,
            },
          },
        },
        Project: {
          fields: {
            ciVariables: {
              keyArgs: ['fullPath'],
              merge,
            },
          },
        },
        Group: {
          fields: {
            ciVariables: {
              keyArgs: ['fullPath'],
              merge,
            },
          },
        },
      },
    },
  };
};
