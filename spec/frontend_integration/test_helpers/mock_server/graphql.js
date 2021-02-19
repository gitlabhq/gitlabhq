import { buildSchema, graphql } from 'graphql';

/* eslint-disable import/no-unresolved */
// This rule is disabled for the following line.
// The graphql schema is dynamically generated in CI
// during the `graphql-schema-dump` job.
import gitlabSchemaStr from '../../../../tmp/tests/graphql/gitlab_schema.graphql';
/* eslint-enable import/no-unresolved */

const graphqlSchema = buildSchema(gitlabSchemaStr.loc.source.body);
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

export const graphqlQuery = (query, variables, schema) =>
  graphql(graphqlSchema, query, graphqlResolvers, schema, variables);
