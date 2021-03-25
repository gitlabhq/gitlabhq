import { buildSchema, graphql } from 'graphql';
import { memoize } from 'lodash';

// The graphql schema is dynamically generated in CI
// during the `graphql-schema-dump` job.
// eslint-disable-next-line global-require, import/no-unresolved
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
  graphql(buildGraphqlSchema(), query, graphqlResolvers, schema, variables);
