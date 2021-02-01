import { stripTypenames } from './graphql_helpers';

describe('stripTypenames', () => {
  it.each`
    input                                                  | expected
    ${{}}                                                  | ${{}}
    ${{ __typename: 'Foo' }}                               | ${{}}
    ${{ bar: 'bar', __typename: 'Foo' }}                   | ${{ bar: 'bar' }}
    ${{ bar: { __typename: 'Bar' }, __typename: 'Foo' }}   | ${{ bar: {} }}
    ${{ bar: [{ __typename: 'Bar' }], __typename: 'Foo' }} | ${{ bar: [{}] }}
    ${[]}                                                  | ${[]}
    ${[{ __typename: 'Foo' }]}                             | ${[{}]}
    ${[{ bar: [{ a: 1, __typename: 'Bar' }] }]}            | ${[{ bar: [{ a: 1 }] }]}
  `('given $input returns $expected, with all __typename keys removed', ({ input, expected }) => {
    const actual = stripTypenames(input);
    expect(actual).toEqual(expected);
    expect(input).not.toBe(actual);
  });

  it('given null returns null', () => {
    expect(stripTypenames(null)).toEqual(null);
  });
});
