import axios from 'axios';
import {
  convertObjectPropsToCamelCase,
  convertObjectPropsToSnakeCase,
} from '~/lib/utils/common_utils';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import {
  GRAPHQL_GROUP_TYPE,
  GRAPHQL_PROJECT_TYPE,
  groupString,
  instanceString,
  projectString,
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
    _destroy: destroy,
  };
};

const mapVariableTypes = (variables = [], kind) => {
  return variables.map((ciVar) => {
    return {
      __typename: `Ci${kind}Variable`,
      ...convertObjectPropsToCamelCase(ciVar),
      id: convertToGraphQLId('Ci::Variable', ciVar.id),
      variableType: ciVar.variable_type ? ciVar.variable_type.toUpperCase() : ciVar.variableType,
    };
  });
};

const prepareProjectGraphQLResponse = ({ data, id, errors = [] }) => {
  return {
    errors,
    project: {
      __typename: GRAPHQL_PROJECT_TYPE,
      id: convertToGraphQLId(GRAPHQL_PROJECT_TYPE, id),
      ciVariables: {
        __typename: `Ci${GRAPHQL_PROJECT_TYPE}VariableConnection`,
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: '',
          endCursor: '',
        },
        nodes: mapVariableTypes(data.variables, projectString),
      },
    },
  };
};

const prepareGroupGraphQLResponse = ({ data, id, errors = [] }) => {
  return {
    errors,
    group: {
      __typename: GRAPHQL_GROUP_TYPE,
      id: convertToGraphQLId(GRAPHQL_GROUP_TYPE, id),
      ciVariables: {
        __typename: `Ci${GRAPHQL_GROUP_TYPE}VariableConnection`,
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: '',
          endCursor: '',
        },
        nodes: mapVariableTypes(data.variables, groupString),
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

    const graphqlData = prepareProjectGraphQLResponse({ data, id });

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

    const graphqlData = prepareGroupGraphQLResponse({ data, id });

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

export const cacheConfig = {
  cacheConfig: {
    typePolicies: {
      Query: {
        fields: {
          ciVariables: {
            keyArgs: false,
            merge: mergeVariables,
          },
        },
      },
      Project: {
        fields: {
          ciVariables: {
            keyArgs: ['fullPath', 'endpoint', 'id'],
            merge: mergeVariables,
          },
        },
      },
      Group: {
        fields: {
          ciVariables: {
            keyArgs: ['fullPath'],
            merge: mergeVariables,
          },
        },
      },
    },
  },
};
