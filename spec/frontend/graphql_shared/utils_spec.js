import {
  getIdFromGraphQLId,
  convertToGraphQLId,
  convertToGraphQLIds,
  convertFromGraphQLIds,
  convertNodeIdsFromGraphQLIds,
} from '~/graphql_shared/utils';

const mockType = 'Group';
const mockId = 12;
const mockGid = `gid://gitlab/Group/12`;

describe('getIdFromGraphQLId', () => {
  [
    {
      input: '',
      output: null,
    },
    {
      input: null,
      output: null,
    },
    {
      input: 2,
      output: 2,
    },
    {
      input: 'gid://',
      output: null,
    },
    {
      input: 'gid://gitlab/',
      output: null,
    },
    {
      input: 'gid://gitlab/Environments',
      output: null,
    },
    {
      input: 'gid://gitlab/Environments/',
      output: null,
    },
    {
      input: 'gid://gitlab/Environments/123',
      output: 123,
    },
    {
      input: 'gid://gitlab/DesignManagement::Version/2',
      output: 2,
    },
  ].forEach(({ input, output }) => {
    it(`getIdFromGraphQLId returns ${output} when passed ${input}`, () => {
      expect(getIdFromGraphQLId(input)).toBe(output);
    });
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
});

describe('convertToGraphQLIds', () => {
  it('combines $type and $id into $result', () => {
    expect(convertToGraphQLIds(mockType, [mockId])).toStrictEqual([mockGid]);
  });

  it.each`
    type        | ids               | message
    ${mockType} | ${null}           | ${"Cannot read property 'map' of null"}
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
