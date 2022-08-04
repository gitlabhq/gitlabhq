describe('custom matcher toEqualGraphqlFixture', () => {
  const key = 'value';
  const key2 = 'value2';

  describe('positive assertion', () => {
    it.each([
      [{}, {}],
      [{ undef: undefined }, { undef: undefined }],
      [{}, { __typename: 'MyType' }],
      [{ key }, { key, __typename: 'MyType' }],
      [
        { obj: { key } },
        {
          obj: {
            key,
            __typename: 'MyNestedType',
          },
          __typename: 'MyType',
        },
      ],
      [[{ key }], [{ key }]],
      [
        [{ key }],
        [
          {
            key,
            __typename: 'MyCollectionType',
          },
        ],
      ],
    ])('%j equals %j', (received, match) => {
      expect(received).toEqualGraphqlFixture(match);
    });
  });

  describe('negative assertion', () => {
    it.each([
      [{ __typename: 'MyType' }, {}],
      [{ key }, { key2, __typename: 'MyType' }],
      [
        { key, key2 },
        { key2, __typename: 'MyType' },
      ],
      [[{ key }, { key2 }], [{ key }]],
      [
        [{ key, key2 }],
        [
          {
            key,
            __typename: 'MyCollectionType',
          },
        ],
      ],
    ])('%j does not equal %j', (received, match) => {
      expect(received).not.toEqualGraphqlFixture(match);
    });
  });
});
