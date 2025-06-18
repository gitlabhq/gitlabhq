import MockAdapter from 'axios-mock-adapter';
import dashboardGroupsWithChildrenResponse from 'test_fixtures/groups/dashboard/index_with_children.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import { resolvers } from '~/groups/your_work/graphql/resolvers';
import groupsQuery from '~/groups/your_work/graphql/queries/groups.query.graphql';
import axios from '~/lib/utils/axios_utils';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';

describe('your work groups resolver', () => {
  let mockApollo;
  let mockAxios;

  const endpoint = '/dashboard/groups.json';

  const makeQuery = (apiResponse = dashboardGroupsWithChildrenResponse) => {
    mockAxios = new MockAdapter(axios);
    mockAxios.onGet(endpoint).reply(200, apiResponse, {
      'x-per-page': 10,
      'x-page': 2,
      'x-total': 21,
      'x-total-pages': 3,
      'x-next-page': 3,
      'x-prev-page': 1,
    });

    return mockApollo.clients.defaultClient.query({
      query: groupsQuery,
      variables: { search: 'foo', sort: 'created_desc', page: 2 },
    });
  };

  beforeEach(() => {
    mockApollo = createMockApollo([], resolvers(endpoint));
  });

  afterEach(() => {
    mockApollo = null;
  });

  it(`makes API call to ${endpoint} with correct params`, async () => {
    await makeQuery();

    expect(mockAxios.history.get[0].params).toEqual({
      active: true,
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
      webUrl: mockGroup.web_url,
      descriptionHtml: '',
      avatarUrl: null,
      descendantGroupsCount: 1,
      projectsCount: 2,
      groupMembersCount: mockGroup.group_members_count,
      visibility: 'public',
      createdAt: mockGroup.created_at,
      updatedAt: mockGroup.updated_at,
      markedForDeletionOn: mockGroup.marked_for_deletion_on,
      isLinkedToSubscription: mockGroup.is_linked_to_subscription,
      permanentDeletionDate: mockGroup.permanent_deletion_date,
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
    });

    expect(pageInfo).toEqual({
      __typename: 'LocalPageInfo',
      total: 21,
      perPage: 10,
      nextPage: 3,
      previousPage: 1,
    });
  });

  describe('when stats are undefined', () => {
    it('returns null', async () => {
      const {
        data: {
          groups: { nodes },
        },
      } = await makeQuery(
        dashboardGroupsWithChildrenResponse.map((group) => ({
          ...group,
          group_members_count: undefined,
          subgroup_count: undefined,
          project_count: undefined,
        })),
      );

      expect(nodes[0]).toMatchObject({
        descendantGroupsCount: null,
        projectsCount: null,
        groupMembersCount: null,
      });
    });
  });

  describe('when permission_integer is undefined', () => {
    it('returns 0 for maxAccessLevel', async () => {
      const {
        data: {
          groups: { nodes },
        },
      } = await makeQuery(
        dashboardGroupsWithChildrenResponse.map((group) => ({
          ...group,
          permission_integer: undefined,
        })),
      );

      expect(nodes[0]).toMatchObject({
        maxAccessLevel: { integerValue: 0 },
      });
    });
  });

  describe('when subgroup_count is undefined', () => {
    it('returns 0 for childrenCount', async () => {
      const {
        data: {
          groups: { nodes },
        },
      } = await makeQuery(
        dashboardGroupsWithChildrenResponse.map((group) => ({
          ...group,
          subgroup_count: undefined,
        })),
      );

      expect(nodes[0].childrenCount).toBe(0);
    });
  });
});
