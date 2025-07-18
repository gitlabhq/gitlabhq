import dashboardGroupsWithChildrenResponse from 'test_fixtures/groups/dashboard/index_with_children.json';
import { formatGroupForGraphQLResolver } from '~/groups/your_work/graphql/utils';
import { formatGroups } from '~/groups/your_work/utils';
import { formatGraphQLGroups } from '~/vue_shared/components/groups_list/formatter';

describe('formatGroups', () => {
  it('returns result from formatGraphQLGroups, adds editPath, and modifies avatarLabel', () => {
    const graphQLGroups = dashboardGroupsWithChildrenResponse.map(formatGroupForGraphQLResolver);

    expect(formatGroups(graphQLGroups)).toEqual(
      formatGraphQLGroups(graphQLGroups).map((group) => ({
        ...group,
        editPath: `${group.webUrl}/-/edit`,
        avatarLabel: group.name,
        children: expect.any(Object),
      })),
    );
  });
});
