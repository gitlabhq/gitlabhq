import { persistenceMapper } from '~/lib/apollo/persistence_mapper';
import NON_PERSISTED_CACHE from './mock_data/non_persisted_cache.json';
import CACHE_WITH_PERSIST_DIRECTIVE from './mock_data/cache_with_persist_directive.json';
import CACHE_WITH_PERSIST_DIRECTIVE_AND_FIELDS from './mock_data/cache_with_persist_directive_and_field.json';

describe('lib/apollo/persistence_mapper', () => {
  it('returns only empty root query if `@persist` directive or `__persist` field is not present', async () => {
    const persistedData = await persistenceMapper(JSON.stringify(NON_PERSISTED_CACHE));

    expect(JSON.parse(persistedData)).toEqual({ ROOT_QUERY: { __typename: 'Query' } });
  });

  it('returns root query with one `project` field if only `@persist` directive is present', async () => {
    const persistedData = await persistenceMapper(JSON.stringify(CACHE_WITH_PERSIST_DIRECTIVE));

    expect(JSON.parse(persistedData)).toEqual({
      ROOT_QUERY: {
        __typename: 'Query',
        'project({"fullPath":"flightjs/Flight"}) @persist': {
          __ref: 'Project:gid://gitlab/Project/6',
        },
      },
      'Project:gid://gitlab/Project/6': { __typename: 'Project', id: 'gid://gitlab/Project/6' },
    });
  });

  it('returns root query nested fields that contain `__persist` field if `@persist` directive is present', async () => {
    const persistedData = await persistenceMapper(
      JSON.stringify(CACHE_WITH_PERSIST_DIRECTIVE_AND_FIELDS),
    );

    expect(JSON.parse(persistedData)).toEqual({
      ROOT_QUERY: {
        __typename: 'Query',
        'project({"fullPath":"flightjs/Flight"}) @persist': {
          __ref: 'Project:gid://gitlab/Project/6',
        },
      },
      'Project:gid://gitlab/Project/6': {
        __typename: 'Project',
        id: 'gid://gitlab/Project/6',
        'issues({"after":null,"before":"eyJ1cGRhdGVkX2F0IjoiMjAyMy0wMS0wOSAwNDowNToyOS4yMzI5NDUwMDAgKzAwMDAiLCJpZCI6IjE1NjYifQ","includeSubepics":true,"last":20,"sort":"UPDATED_DESC","state":"opened","types":["ISSUE","INCIDENT","TEST_CASE","TASK"]})':
          {
            __typename: 'IssueConnection',
            __persist: true,
            pageInfo: {
              __typename: 'PageInfo',
              hasNextPage: true,
              hasPreviousPage: false,
              startCursor:
                'eyJ1cGRhdGVkX2F0IjoiMjAyMy0wMS0xMCAxMjozNjo1NC41NDYxNzEwMDAgKzAwMDAiLCJpZCI6IjQ4MyJ9',
              endCursor:
                'eyJ1cGRhdGVkX2F0IjoiMjAyMy0wMS0wOSAwNDowNToyOS4zMDE3NDcwMDAgKzAwMDAiLCJpZCI6IjE1NjcifQ',
            },
            nodes: [
              {
                __ref: 'Issue:gid://gitlab/Issue/483',
              },
              {
                __ref: 'Issue:gid://gitlab/Issue/1585',
              },
              {
                __ref: 'Issue:gid://gitlab/Issue/1584',
              },
              {
                __ref: 'Issue:gid://gitlab/Issue/1583',
              },
              {
                __ref: 'Issue:gid://gitlab/Issue/1582',
              },
              {
                __ref: 'Issue:gid://gitlab/Issue/1581',
              },
              {
                __ref: 'Issue:gid://gitlab/Issue/1580',
              },
              {
                __ref: 'Issue:gid://gitlab/Issue/1579',
              },
              {
                __ref: 'Issue:gid://gitlab/Issue/1578',
              },
              {
                __ref: 'Issue:gid://gitlab/Issue/1577',
              },
              {
                __ref: 'Issue:gid://gitlab/Issue/1576',
              },
              {
                __ref: 'Issue:gid://gitlab/Issue/1575',
              },
              {
                __ref: 'Issue:gid://gitlab/Issue/1574',
              },
              {
                __ref: 'Issue:gid://gitlab/Issue/1573',
              },
              {
                __ref: 'Issue:gid://gitlab/Issue/1572',
              },
              {
                __ref: 'Issue:gid://gitlab/Issue/1571',
              },
              {
                __ref: 'Issue:gid://gitlab/Issue/1570',
              },
              {
                __ref: 'Issue:gid://gitlab/Issue/1569',
              },
              {
                __ref: 'Issue:gid://gitlab/Issue/1568',
              },
              {
                __ref: 'Issue:gid://gitlab/Issue/1567',
              },
            ],
          },
      },
      'Issue:gid://gitlab/Issue/483': {
        __typename: 'Issue',
        __persist: true,
        id: 'gid://gitlab/Issue/483',
        iid: '31',
        confidential: false,
        createdAt: '2022-09-11T15:24:16Z',
        downvotes: 1,
        dueDate: null,
        hidden: false,
        humanTimeEstimate: null,
        mergeRequestsCount: 1,
        moved: false,
        state: 'opened',
        title: 'Instigate the Incident!',
        updatedAt: '2023-01-10T12:36:54Z',
        closedAt: null,
        upvotes: 0,
        userDiscussionsCount: 2,
        webPath: '/flightjs/Flight/-/issues/31',
        webUrl: 'https://gdk.test:3443/flightjs/Flight/-/issues/31',
        type: 'INCIDENT',
        assignees: {
          __typename: 'UserCoreConnection',
          nodes: [],
        },
        author: {
          __ref: 'UserCore:gid://gitlab/User/1',
        },
        labels: {
          __typename: 'LabelConnection',
          nodes: [],
        },
        milestone: null,
        taskCompletionStatus: {
          __typename: 'TaskCompletionStatus',
          completedCount: 0,
          count: 0,
        },
        blockingCount: 0,
        healthStatus: null,
        weight: null,
      },
    });
  });
});
