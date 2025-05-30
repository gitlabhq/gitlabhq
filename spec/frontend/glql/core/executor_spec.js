import { gql } from '@apollo/client/core';
import Executor, { resolveToScalar, transformGIDToString } from '~/glql/core/executor';
import createDefaultClient from '~/lib/graphql';
import { MOCK_ISSUES } from '../mock_data';

jest.mock('~/lib/graphql', () => jest.fn());

const MOCK_QUERY_RESPONSE = { project: { issues: MOCK_ISSUES } };

describe('Executor', () => {
  let executor;
  let queryFn;

  const mockQueryResponse = (...responses) => {
    queryFn = jest.fn();
    responses.forEach((response) => {
      queryFn.mockResolvedValueOnce({ data: response });
    });
    createDefaultClient.mockReturnValue({
      query: queryFn,
    });
  };

  beforeEach(async () => {
    gon.current_username = 'foobar';
    mockQueryResponse(MOCK_QUERY_RESPONSE);
    executor = await new Executor().init();
  });

  afterEach(() => {
    delete gon.current_username;
  });

  it('executes a query using a graphql client', async () => {
    const data = await executor.execute(`
      {
        issues(assigneeUsernames: "foobar", first: 100) {
          nodes { id iid title webUrl reference state type }
          pageInfo { endCursor hasNextPage }
        }
      }
      `);

    expect(data).toEqual(MOCK_QUERY_RESPONSE);
  });

  it('executes a query with variables', async () => {
    const mockEpicQuery = `query { group(fullPath: "gitlab-org") { epics(iid: "123") { id } } }`;
    const mockIssueQuery = `query GLQL($epicId: String) { project(fullPath: "gitlab-org/gitlab") { issues(epicId: $epicId) { nodes { id title} } } }`;

    const mockEpicResponse = { group: { epics: [{ id: 'gid://gitlab/Epic/123' }] } };
    const mockIssueResponse = { project: { issues: { nodes: MOCK_ISSUES } } };

    mockQueryResponse(mockEpicResponse, mockIssueResponse);
    executor = await new Executor().init();

    const data = await executor.execute(mockIssueQuery, [
      {
        key: 'epicId',
        data: mockEpicQuery,
        data_type: 'String',
      },
    ]);

    expect(data).toEqual(mockIssueResponse);
    expect(queryFn).toHaveBeenCalledTimes(2);
    expect(queryFn).toHaveBeenNthCalledWith(
      1,
      expect.objectContaining({
        query: gql`
          ${mockEpicQuery}
        `,
      }),
    );
    expect(queryFn).toHaveBeenNthCalledWith(
      2,
      expect.objectContaining({
        query: gql`
          ${mockIssueQuery}
        `,
        variables: {
          epicId: '123',
        },
      }),
    );
  });
});

describe('resolveToScalar', () => {
  it('returns the scalar value for a simple object', () => {
    expect(resolveToScalar({ id: 42 })).toBe(42);
  });

  it('recursively resolves nested objects', () => {
    expect(resolveToScalar({ foo: { bar: { baz: 'value' } } })).toBe('value');
  });

  it('ignores __typename keys', () => {
    expect(resolveToScalar({ __typename: 'Type', id: 'abc' })).toBe('abc');
  });
});

describe('transformGIDToString', () => {
  it('returns the last part of a GID string when type is String', () => {
    expect(transformGIDToString('gid://gitlab/Issue/123', 'String')).toBe('123');
  });

  it('returns the original data if type is not String', () => {
    expect(transformGIDToString('gid://gitlab/Issue/123', 'ID')).toBe('gid://gitlab/Issue/123');
  });

  it('returns undefined if data is undefined and type is String', () => {
    expect(transformGIDToString(undefined, 'String')).toBeUndefined();
  });
});
