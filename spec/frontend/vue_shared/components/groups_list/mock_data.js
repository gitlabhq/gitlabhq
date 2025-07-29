import adminGroupsGraphQlResponse from 'test_fixtures/graphql/admin/groups.query.graphql.json';
import { formatGraphQLGroups } from '~/vue_shared/components/groups_list/formatter';

const {
  data: {
    groups: { nodes: graphqlGroups },
  },
} = adminGroupsGraphQlResponse;

const groups = formatGraphQLGroups(graphqlGroups);

export { groups };
