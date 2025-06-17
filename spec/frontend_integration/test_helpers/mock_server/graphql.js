import { buildSchema, graphql } from 'graphql';
import { memoize } from 'lodash';

// eslint-disable-next-line global-require
const getGraphqlSchema = () => require('../../../../tmp/tests/graphql/gitlab_schema.graphql');

const graphqlResolvers = {
  project({ fullPath }, schema) {
    const result = schema.projects.findBy({ path_with_namespace: fullPath });
    const userPermission = schema.db.userPermissions[0];

    return {
      ...result.attrs,
      userPermissions: {
        ...userPermission,
      },
    };
  },
};
const buildGraphqlSchema = memoize(() => buildSchema(getGraphqlSchema().loc.source.body));

export const graphqlQuery = (query, variables, schema) =>
  graphql({
    schema: buildGraphqlSchema(),
    source: query,
    rootValue: graphqlResolvers,
    contextValue: schema,
    variableValues: variables,
  });
