import { buildSchema, graphql } from 'graphql';
import gitlabSchemaStr from '../../../../doc/api/graphql/reference/gitlab_schema.graphql';

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

// eslint-disable-next-line import/prefer-default-export
export const graphqlQuery = (query, variables, schema) =>
  graphql(graphqlSchema, query, graphqlResolvers, schema, variables);
