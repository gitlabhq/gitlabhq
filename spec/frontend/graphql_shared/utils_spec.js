import Visibility from 'visibilityjs';

import {
  isGid,
  getIdFromGraphQLId,
  getTypeFromGraphQLId,
  convertToGraphQLId,
  convertToGraphQLIds,
  convertFromGraphQLIds,
  convertNodeIdsFromGraphQLIds,
  getNodesOrDefault,
  toggleQueryPollingByVisibility,
  etagQueryHeaders,
  calculateGraphQLPaginationQueryParams,
} from '~/graphql_shared/utils';

const mockType = 'Group';
const mockId = 12;
const mockGid = `gid://gitlab/Group/12`;

describe('isGid', () => {
  it('returns true if passed id is gid', () => {
    expect(isGid(mockGid)).toBe(true);
  });

  it('returns false if passed id is not gid', () => {
    expect(isGid(mockId)).toBe(false);
  });
});

describe.each`
  input                                           | id      | type
  ${''}                                           | ${null} | ${null}
  ${null}                                         | ${null} | ${null}
  ${0}                                            | ${0}    | ${null}
  ${'0'}                                          | ${0}    | ${null}
  ${2}                                            | ${2}    | ${null}
  ${'2'}                                          | ${2}    | ${null}
  ${'gid://'}                                     | ${null} | ${null}
  ${'gid://gitlab'}                               | ${null} | ${null}
  ${'gid://gitlab/'}                              | ${null} | ${null}
  ${'gid://gitlab/Environments'}                  | ${null} | ${'Environments'}
  ${'gid://gitlab/Environments/'}                 | ${null} | ${'Environments'}
  ${'gid://gitlab/Environments/0'}                | ${0}    | ${'Environments'}
  ${'gid://gitlab/Environments/123'}              | ${123}  | ${'Environments'}
  ${'gid://gitlab/Environments/123/test'}         | ${123}  | ${'Environments'}
  ${'gid://gitlab/DesignManagement::Version/123'} | ${123}  | ${'DesignManagement::Version'}
`('parses GraphQL ID `$input`', ({ input, id, type }) => {
  it(`getIdFromGraphQLId returns ${id}`, () => {
    expect(getIdFromGraphQLId(input)).toBe(id);
  });

  it(`getTypeFromGraphQLId returns ${type}`, () => {
    expect(getTypeFromGraphQLId(input)).toBe(type);
  });
});

describe('convertToGraphQLId', () => {
  it('combines $type and $id into $result', () => {
    expect(convertToGraphQLId(mockType, mockId)).toBe(mockGid);
  });

  it.each`
    type        | id        | message
    ${mockType} | ${null}   | ${'id must be a number or string; got object'}
    ${null}     | ${mockId} | ${'type must be a string; got object'}
  `('throws TypeError with "$message" if a param is missing', ({ type, id, message }) => {
    expect(() => convertToGraphQLId(type, id)).toThrow(new TypeError(message));
  });

  it('returns id as is if it follows the gid format', () => {
    expect(convertToGraphQLId(mockType, mockGid)).toStrictEqual(mockGid);
  });
});

describe('convertToGraphQLIds', () => {
  it('combines $type and $id into $result', () => {
    expect(convertToGraphQLIds(mockType, [mockId])).toStrictEqual([mockGid]);
  });

  it.each`
    type        | ids               | message
    ${mockType} | ${null}           | ${"Cannot read properties of null (reading 'map')"}
    ${mockType} | ${[mockId, null]} | ${'id must be a number or string; got object'}
    ${null}     | ${[mockId]}       | ${'type must be a string; got object'}
  `('throws TypeError with "$message" if a param is missing', ({ type, ids, message }) => {
    expect(() => convertToGraphQLIds(type, ids)).toThrow(new TypeError(message));
  });
});

describe('convertFromGraphQLIds', () => {
  it.each`
    ids                        | expected
    ${[mockGid]}               | ${[mockId]}
    ${[mockGid, 'invalid id']} | ${[mockId, null]}
  `('converts $ids from GraphQL Ids', ({ ids, expected }) => {
    expect(convertFromGraphQLIds(ids)).toEqual(expected);
  });

  it("throws TypeError if `ids` parameter isn't an array", () => {
    expect(() => convertFromGraphQLIds('invalid')).toThrow(
      new TypeError('ids must be an array; got string'),
    );
  });
});

describe('convertNodeIdsFromGraphQLIds', () => {
  it.each`
    nodes                                                               | expected
    ${[{ id: mockGid, name: 'foo bar' }, { id: mockGid, name: 'baz' }]} | ${[{ id: mockId, name: 'foo bar' }, { id: mockId, name: 'baz' }]}
    ${[{ name: 'foo bar' }]}                                            | ${[{ name: 'foo bar' }]}
  `('converts `id` properties in $nodes from GraphQL Id', ({ nodes, expected }) => {
    expect(convertNodeIdsFromGraphQLIds(nodes)).toEqual(expected);
  });

  it("throws TypeError if `nodes` parameter isn't an array", () => {
    expect(() => convertNodeIdsFromGraphQLIds('invalid')).toThrow(
      new TypeError('nodes must be an array; got string'),
    );
  });
});

describe('getNodesOrDefault', () => {
  const mockDataWithNodes = {
    users: {
      nodes: [
        { __typename: 'UserCore', id: 'gid://gitlab/User/44' },
        { __typename: 'UserCore', id: 'gid://gitlab/User/42' },
        { __typename: 'UserCore', id: 'gid://gitlab/User/41' },
      ],
    },
  };

  it.each`
    desc                                     | input                               | expected
    ${'with nodes child'}                    | ${[mockDataWithNodes.users]}        | ${mockDataWithNodes.users.nodes}
    ${'with nodes child and "dne" as field'} | ${[mockDataWithNodes.users, 'dne']} | ${[]}
    ${'with empty data object'}              | ${[{ users: {} }]}                  | ${[]}
    ${'with empty object'}                   | ${[{}]}                             | ${[]}
    ${'with falsy value'}                    | ${[undefined]}                      | ${[]}
  `('$desc', ({ input, expected }) => {
    const result = getNodesOrDefault(...input);

    expect(result).toEqual(expected);
  });
});

describe('toggleQueryPollingByVisibility', () => {
  let query;
  let changeFn;
  let interval;
  let hidden;

  beforeEach(() => {
    hidden = jest.spyOn(Visibility, 'hidden').mockReturnValue(true);
    jest.spyOn(Visibility, 'change').mockImplementation((fn) => {
      changeFn = fn;
    });

    query = { startPolling: jest.fn(), stopPolling: jest.fn() };
    interval = 5000;

    toggleQueryPollingByVisibility(query, 5000);
  });

  it('starts polling not hidden', () => {
    hidden.mockReturnValue(false);

    changeFn();
    expect(query.startPolling).toHaveBeenCalledWith(interval);
  });

  it('stops polling when hidden', () => {
    query.stopPolling.mockReset();
    hidden.mockReturnValue(true);

    changeFn();
    expect(query.stopPolling).toHaveBeenCalled();
  });
});

describe('etagQueryHeaders', () => {
  it('returns headers necessary for etag caching', () => {
    expect(etagQueryHeaders('myFeature', 'myResource')).toEqual({
      fetchOptions: {
        method: 'GET',
      },
      headers: {
        'X-GITLAB-GRAPHQL-FEATURE-CORRELATION': 'myFeature',
        'X-GITLAB-GRAPHQL-RESOURCE-ETAG': 'myResource',
        'X-Requested-With': 'XMLHttpRequest',
      },
    });
  });
});

describe('calculateGraphQLPaginationQueryParams', () => {
  const mockRouteQuery = { start_cursor: 'mockStartCursor', end_cursor: 'mockEndCursor' };

  describe('when `startCursor` is defined', () => {
    it('sets start cursor query param', () => {
      expect(
        calculateGraphQLPaginationQueryParams({
          startCursor: 'newMockStartCursor',
          routeQuery: mockRouteQuery,
        }),
      ).toEqual({ start_cursor: 'newMockStartCursor' });
    });
  });

  describe('when `endCursor` is defined', () => {
    it('sets end cursor query param', () => {
      expect(
        calculateGraphQLPaginationQueryParams({
          endCursor: 'newMockEndCursor',
          routeQuery: mockRouteQuery,
        }),
      ).toEqual({ end_cursor: 'newMockEndCursor' });
    });
  });
});
