import MockAdapter from 'axios-mock-adapter';
import dashboardGroupsWithChildrenResponse from 'test_fixtures/groups/dashboard/index_with_children.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import { resolvers } from '~/groups/your_work/graphql/resolvers';
import memberGroupsQuery from '~/groups/your_work/graphql/queries/member_groups.query.graphql';
import axios from '~/lib/utils/axios_utils';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';

describe('your work groups resolver', () => {
  let mockApollo;
  let mockAxios;

  const endpoint = '/dashboard/groups.json';

  const makeQuery = () => {
    return mockApollo.clients.defaultClient.query({
      query: memberGroupsQuery,
      variables: { search: 'foo', sort: 'created_desc', page: 2 },
    });
  };

  beforeEach(() => {
    mockApollo = createMockApollo([], resolvers(endpoint));

    mockAxios = new MockAdapter(axios);
    mockAxios.onGet(endpoint).reply(200, dashboardGroupsWithChildrenResponse, {
      'x-per-page': 10,
      'x-page': 2,
      'x-total': 21,
      'x-total-pages': 3,
      'x-next-page': 3,
      'x-prev-page': 1,
    });
  });

  afterEach(() => {
    mockApollo = null;
  });

  it(`makes API call to ${endpoint} with correct params`, async () => {
    await makeQuery();

    expect(mockAxios.history.get[0].params).toEqual({
      filter: 'foo',
      sort: 'created_desc',
      page: 2,
    });
  });

  it('returns API call response correctly formatted for GraphQL', async () => {
    const {
      data: {
        groups: { nodes, pageInfo },
      },
    } = await makeQuery();

    const [mockGroup] = dashboardGroupsWithChildrenResponse;

    expect(nodes[0]).toMatchObject({
      __typename: TYPENAME_GROUP,
      id: convertToGraphQLId(TYPENAME_GROUP, mockGroup.id),
      fullPath: '/frontend-fixtures-group',
      fullName: 'frontend-fixtures-group',
      parent: { id: null },
      webUrl: '/frontend-fixtures-group',
      organizationEditPath: '',
      descriptionHtml: '',
      avatarUrl: null,
      descendantGroupsCount: 1,
      projectsCount: 2,
      groupMembersCount: 0,
      visibility: 'public',
      createdAt: mockGroup.created_at,
      updatedAt: mockGroup.updated_at,
      userPermissions: {
        canLeave: false,
        removeGroup: true,
        viewEditPage: true,
      },
      maxAccessLevel: { integerValue: 50 },
      children: [
        {
          id: convertToGraphQLId(TYPENAME_GROUP, mockGroup.children[0].id),
          avatarUrl: null,
          descendantGroupsCount: 1,
          children: [
            {
              id: convertToGraphQLId(TYPENAME_GROUP, mockGroup.children[0].children[0].id),
              avatarUrl: null,
              descendantGroupsCount: 0,
            },
          ],
        },
      ],
      childrenCount: 1,
      isLinkedToSubscription: false,
    });

    expect(pageInfo).toEqual({
      __typename: 'LocalPageInfo',
      total: 21,
      perPage: 10,
      nextPage: 3,
      previousPage: 1,
    });
  });
});
