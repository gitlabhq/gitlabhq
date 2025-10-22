import MockAdapter from 'axios-mock-adapter';
import childrenResponse from 'test_fixtures/groups/children.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import { resolvers } from '~/groups/show/graphql/resolvers';
import subgroupsAndProjectsQuery from '~/groups/show/graphql/queries/subgroups_and_projects.query.graphql';
import axios from '~/lib/utils/axios_utils';
import { TYPENAME_GROUP, TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';

describe('groups show resolver', () => {
  let mockApollo;
  let mockAxios;

  const endpoint = '/groups/foo/-/children.json';

  const makeQuery = (apiResponse = childrenResponse) => {
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
      query: subgroupsAndProjectsQuery,
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
      filter: 'foo',
      sort: 'created_desc',
      page: 2,
    });
  });

  it('returns API call response correctly formatted for GraphQL', async () => {
    const {
      data: {
        subgroupsAndProjects: { nodes, pageInfo },
      },
    } = await makeQuery();

    const [mockProject, mockProject2, mockGroup] = childrenResponse;
    const [mockSubproject, mockSubgroup] = mockGroup.children;
    const [mockNestedSubproject] = mockSubgroup.children;

    expect(nodes).toEqual([
      {
        __typename: TYPENAME_PROJECT,
        name: mockProject.name,
        type: 'project',
        editPath: mockProject.edit_path,
        id: convertToGraphQLId(TYPENAME_PROJECT, mockProject.id),
        fullPath: mockProject.full_path,
        archived: mockProject.archived,
        nameWithNamespace: mockProject.full_name,
        webUrl: mockProject.web_url,
        topics: [],
        forksCount: 0,
        avatarUrl: null,
        starCount: 0,
        visibility: mockProject.visibility,
        openMergeRequestsCount: 0,
        openIssuesCount: 0,
        descriptionHtml: '',
        createdAt: mockProject.created_at,
        updatedAt: mockProject.updated_at,
        lastActivityAt: mockProject.last_activity_at,
        group: null,
        mergeRequestsAccessLevel: { stringValue: 'disabled' },
        issuesAccessLevel: { stringValue: 'disabled' },
        forkingAccessLevel: { stringValue: 'disabled' },
        userPermissions: {
          archiveProject: true,
          removeProject: true,
          viewEditPage: true,
        },
        maxAccessLevel: { integerValue: 0 },
        isCatalogResource: false,
        exploreCatalogPath: '',
        isPublished: false,
        pipeline: null,
        markedForDeletion: false,
        isSelfDeletionInProgress: false,
        isSelfDeletionScheduled: false,
        permanentDeletionDate: mockProject.permanent_deletion_date,
      },
      {
        __typename: TYPENAME_PROJECT,
        name: mockProject2.name,
        type: 'project',
        editPath: mockProject2.edit_path,
        id: convertToGraphQLId(TYPENAME_PROJECT, mockProject2.id),
        fullPath: mockProject2.full_path,
        archived: mockProject2.archived,
        nameWithNamespace: mockProject2.full_name,
        webUrl: mockProject2.web_url,
        topics: [],
        forksCount: 0,
        avatarUrl: null,
        starCount: 0,
        visibility: mockProject2.visibility,
        openMergeRequestsCount: 0,
        openIssuesCount: 0,
        descriptionHtml: '',
        createdAt: mockProject2.created_at,
        updatedAt: mockProject2.updated_at,
        lastActivityAt: mockProject2.last_activity_at,
        group: null,
        mergeRequestsAccessLevel: { stringValue: 'disabled' },
        issuesAccessLevel: { stringValue: 'disabled' },
        forkingAccessLevel: { stringValue: 'disabled' },
        userPermissions: {
          archiveProject: true,
          removeProject: true,
          viewEditPage: true,
        },
        maxAccessLevel: { integerValue: 0 },
        isCatalogResource: false,
        exploreCatalogPath: '',
        isPublished: false,
        pipeline: null,
        markedForDeletion: false,
        isSelfDeletionInProgress: false,
        isSelfDeletionScheduled: false,
        permanentDeletionDate: mockProject2.permanent_deletion_date,
      },
      {
        __typename: TYPENAME_GROUP,
        type: 'group',
        editPath: mockGroup.edit_path,
        hasChildren: true,
        childrenCount: 2,
        id: convertToGraphQLId(TYPENAME_GROUP, mockGroup.id),
        name: mockGroup.name,
        fullPath: mockGroup.full_path,
        fullName: mockGroup.full_name,
        parent: { id: mockGroup.parent_id },
        webUrl: mockGroup.web_url,
        descriptionHtml: '',
        avatarUrl: null,
        descendantGroupsCount: 1,
        projectsCount: 1,
        groupMembersCount: 0,
        visibility: 'public',
        createdAt: mockGroup.created_at,
        updatedAt: mockGroup.updated_at,
        userPermissions: {
          archiveGroup: true,
          canLeave: false,
          removeGroup: true,
          viewEditPage: true,
        },
        maxAccessLevel: { integerValue: 0 },
        isLinkedToSubscription: false,
        archived: false,
        markedForDeletion: false,
        isSelfDeletionInProgress: false,
        isSelfDeletionScheduled: false,
        permanentDeletionDate: mockGroup.permanent_deletion_date,
        children: [
          {
            __typename: TYPENAME_PROJECT,
            name: mockSubproject.name,
            type: 'project',
            editPath: mockSubproject.edit_path,
            id: convertToGraphQLId(TYPENAME_PROJECT, mockSubproject.id),
            fullPath: mockSubproject.full_path,
            archived: mockSubproject.archived,
            nameWithNamespace: mockSubproject.full_name,
            webUrl: mockSubproject.web_url,
            topics: [],
            forksCount: 0,
            avatarUrl: null,
            starCount: 0,
            visibility: mockSubproject.visibility,
            openMergeRequestsCount: 0,
            openIssuesCount: 0,
            descriptionHtml: '',
            createdAt: mockSubproject.created_at,
            updatedAt: mockSubproject.updated_at,
            lastActivityAt: mockSubproject.last_activity_at,
            group: null,
            mergeRequestsAccessLevel: { stringValue: 'disabled' },
            issuesAccessLevel: { stringValue: 'disabled' },
            forkingAccessLevel: { stringValue: 'disabled' },
            userPermissions: {
              archiveProject: true,
              removeProject: true,
              viewEditPage: true,
            },
            maxAccessLevel: { integerValue: 0 },
            isCatalogResource: false,
            exploreCatalogPath: '',
            isPublished: false,
            pipeline: null,
            markedForDeletion: false,
            isSelfDeletionInProgress: false,
            isSelfDeletionScheduled: false,
            permanentDeletionDate: mockSubproject.permanent_deletion_date,
          },
          {
            __typename: TYPENAME_GROUP,
            type: 'group',
            editPath: mockSubgroup.edit_path,
            hasChildren: true,
            childrenCount: 1,
            id: convertToGraphQLId(TYPENAME_GROUP, mockSubgroup.id),
            name: mockSubgroup.name,
            fullPath: mockSubgroup.full_path,
            fullName: mockSubgroup.full_name,
            parent: { id: mockSubgroup.parent_id },
            webUrl: mockSubgroup.web_url,
            descriptionHtml: '',
            avatarUrl: null,
            descendantGroupsCount: 0,
            projectsCount: 1,
            groupMembersCount: 0,
            visibility: 'public',
            createdAt: mockSubgroup.created_at,
            updatedAt: mockSubgroup.updated_at,
            userPermissions: {
              archiveGroup: true,
              canLeave: false,
              removeGroup: true,
              viewEditPage: true,
            },
            maxAccessLevel: { integerValue: 0 },
            isLinkedToSubscription: false,
            archived: false,
            markedForDeletion: false,
            isSelfDeletionInProgress: false,
            isSelfDeletionScheduled: false,
            permanentDeletionDate: mockSubgroup.permanent_deletion_date,
            children: [
              {
                __typename: TYPENAME_PROJECT,
                name: mockNestedSubproject.name,
                type: 'project',
                editPath: mockNestedSubproject.edit_path,
                id: convertToGraphQLId(TYPENAME_PROJECT, mockNestedSubproject.id),
                fullPath: mockNestedSubproject.full_path,
                archived: mockNestedSubproject.archived,
                nameWithNamespace: mockNestedSubproject.full_name,
                webUrl: mockNestedSubproject.web_url,
                topics: [],
                forksCount: 0,
                avatarUrl: null,
                starCount: 0,
                visibility: mockNestedSubproject.visibility,
                openMergeRequestsCount: 0,
                openIssuesCount: 0,
                descriptionHtml: '',
                createdAt: mockNestedSubproject.created_at,
                updatedAt: mockNestedSubproject.updated_at,
                lastActivityAt: mockNestedSubproject.last_activity_at,
                group: null,
                mergeRequestsAccessLevel: { stringValue: 'disabled' },
                issuesAccessLevel: { stringValue: 'disabled' },
                forkingAccessLevel: { stringValue: 'disabled' },
                userPermissions: {
                  archiveProject: true,
                  removeProject: true,
                  viewEditPage: true,
                },
                maxAccessLevel: { integerValue: 0 },
                isCatalogResource: false,
                exploreCatalogPath: '',
                isPublished: false,
                pipeline: null,
                markedForDeletion: false,
                isSelfDeletionInProgress: false,
                isSelfDeletionScheduled: false,
                permanentDeletionDate: mockNestedSubproject.permanent_deletion_date,
              },
            ],
          },
        ],
      },
    ]);

    expect(pageInfo).toEqual({
      __typename: 'LocalPageInfo',
      total: 21,
      perPage: 10,
      nextPage: 3,
      previousPage: 1,
    });
  });
});
