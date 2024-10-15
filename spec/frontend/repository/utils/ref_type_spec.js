import { getRefType } from '~/repository/utils/ref_type';

describe('getRefType', () => {
  it.each`
    refType          | expected
    ${'heads'}       | ${'HEADS'}
    ${'HEADS'}       | ${'HEADS'}
    ${'tags'}        | ${'TAGS'}
    ${'TAGS'}        | ${'TAGS'}
    ${'fakereftype'} | ${null}
    ${''}            | ${null}
    ${null}          | ${null}
  `('returns $expected for "$refType"', ({ refType, expected }) => {
    expect(getRefType(refType)).toBe(expected);
  });
});
