import { bucketDateOf, formatBucketDate } from '~/glql/utils/date_bucket';

describe('bucketDateOf', () => {
  // Daily bucket starts arrive as ISO datetimes (ClickHouse's
  // toStartOfInterval returns DateTime for day intervals) while weekly and
  // monthly arrive date-only.
  it.each`
    value                          | expected
    ${'2026-06-01'}                | ${'2026-06-01'}
    ${'2026-08-03T00:00:00Z'}      | ${'2026-08-03'}
    ${'2026-08-03T00:00:00.000Z'}  | ${'2026-08-03'}
    ${'2026-08-03T00:00:00+02:00'} | ${'2026-08-03'}
  `('extracts the date part of $value', ({ value, expected }) => {
    expect(bucketDateOf(value)).toBe(expected);
  });

  it.each([
    '2026-01-01 00:00:00',
    '2026-01-01Tjunk',
    '2026-02-30T00:00:00Z',
    '2026-01-01T00:00:00+junk',
    '2026-01',
    '2026-01-01-hotfix',
    'v2026-01-01',
    '20260101',
    '2026-02-30',
    '2027-02-29',
    '0099-01-01',
    '2026-01-01 release notes',
    'ruby',
    42,
    null,
    undefined,
    { created: '2026-01-01' },
  ])('returns null for the non-bucket value %p', (value) => {
    expect(bucketDateOf(value)).toBeNull();
  });
});

describe('formatBucketDate', () => {
  it.each`
    granularity  | value           | includeYear | expected
    ${'daily'}   | ${'2026-06-01'} | ${false}    | ${'Jun 1'}
    ${'daily'}   | ${'2026-06-01'} | ${true}     | ${'Jun 1, 2026'}
    ${'weekly'}  | ${'2026-01-12'} | ${false}    | ${'Jan 12 – 18'}
    ${'weekly'}  | ${'2026-06-29'} | ${false}    | ${'Jun 29 – Jul 5'}
    ${'weekly'}  | ${'2026-01-12'} | ${true}     | ${'Jan 12 – 18, 2026'}
    ${'weekly'}  | ${'2026-12-28'} | ${true}     | ${'Dec 28, 2026 – Jan 3, 2027'}
    ${'monthly'} | ${'2026-06-01'} | ${false}    | ${'Jun 2026'}
    ${'yearly'}  | ${'2026-01-01'} | ${true}     | ${'2026'}
  `(
    'formats $value as $expected for $granularity with includeYear=$includeYear',
    ({ granularity, value, includeYear, expected }) => {
      expect(formatBucketDate(value, granularity, includeYear)).toBe(expected);
    },
  );

  it('omits the year by default', () => {
    expect(formatBucketDate('2026-06-01', 'daily')).toBe('Jun 1');
  });

  it('formats ISO datetime bucket starts on their own day', () => {
    expect(formatBucketDate('2026-08-03T00:00:00Z', 'daily')).toBe('Aug 3');
  });

  it('stringifies non-bucket values unchanged', () => {
    expect(formatBucketDate('ruby', 'weekly')).toBe('ruby');
    expect(formatBucketDate(42, 'weekly')).toBe('42');
  });
});
