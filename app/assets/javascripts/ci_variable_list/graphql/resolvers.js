import axios from 'axios';
import {
  convertObjectPropsToCamelCase,
  convertObjectPropsToSnakeCase,
} from '../../lib/utils/common_utils';
import { getIdFromGraphQLId } from '../../graphql_shared/utils';
import { instanceString } from '../constants';
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
      variableType: ciVar.variable_type ? ciVar.variable_type.toUpperCase() : ciVar.variableType,
    };
  });
};

const prepareAdminGraphQLResponse = ({ data, errors = [] }) => {
  return {
    errors,
    ciVariables: {
      __typename: `Ci${instanceString}VariableConnection`,
      nodes: mapVariableTypes(data.variables, instanceString),
    },
  };
};

const callAdminEndpoint = async ({ endpoint, variable, cache, destroy = false }) => {
  try {
    const { data } = await axios.patch(endpoint, {
      variables_attributes: [prepareVariableForApi({ variable, destroy })],
    });

    return prepareAdminGraphQLResponse({ data });
  } catch (e) {
    return prepareAdminGraphQLResponse({
      data: cache.readQuery({ query: getAdminVariables }),
      errors: [...e.response.data],
    });
  }
};

export const resolvers = {
  Mutation: {
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
