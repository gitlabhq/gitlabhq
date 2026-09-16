import {
  dateRangeDayCount,
  dateRangeGranularity,
  resolveDateRangeFilter,
} from '~/explore/analytics_dashboards/components/utils';

// The jest environment freezes today at 2020-07-06.
const LAST_7_DAYS = {
  key: '7d',
  startDate: new Date('2020-06-29T00:00:00.000Z'),
  endDate: new Date('2020-07-06T00:00:00.000Z'),
};
const LAST_30_DAYS = {
  key: '30d',
  startDate: new Date('2020-06-06T00:00:00.000Z'),
  endDate: new Date('2020-07-06T00:00:00.000Z'),
};

describe('resolveDateRangeFilter', () => {
  const startDate = new Date('2026-01-05T00:00:00.000Z');
  const endDate = new Date('2026-03-31T00:00:00.000Z');

  it('resolves the selected option to its own window', () => {
    expect(resolveDateRangeFilter({ dateRangeOption: '7d' })).toMatchObject(LAST_7_DAYS);
  });

  it('falls back to the default selected option when given nothing', () => {
    expect(resolveDateRangeFilter()).toMatchObject(LAST_7_DAYS);
  });

  it('falls back to the given default option for an option it does not know', () => {
    expect(resolveDateRangeFilter({ dateRangeOption: 'last-fortnight' }, '30d')).toMatchObject(
      LAST_30_DAYS,
    );
  });

  it('takes the dates a custom range supplies, keeping the option it came from', () => {
    expect(resolveDateRangeFilter({ dateRangeOption: 'custom', startDate, endDate })).toMatchObject(
      {
        key: 'custom',
        startDate,
        endDate,
      },
    );
  });

  // The picker emits the bounds of a custom range one at a time. Filling the other bound from
  // the default would query a window the user never asked for, running backwards if the end
  // they picked predates it.
  it.each([
    ['no dates', {}],
    ['only a start date', { startDate }],
    ['only an end date', { endDate }],
  ])('falls back to the default option for a custom range with %s', (_, dates) => {
    expect(resolveDateRangeFilter({ dateRangeOption: 'custom', ...dates }, '30d')).toMatchObject(
      LAST_30_DAYS,
    );
  });
});

// A range of `days` whole days, both bounds counted, so `days: 1` is a single day.
const rangeOf = (days) => ({
  startDate: new Date('2026-01-05T00:00:00.000Z'),
  endDate: new Date(Date.UTC(2026, 0, 4 + days)),
});

describe('dateRangeDayCount', () => {
  it.each([
    ['a single day', 1],
    ['a week', 7],
    ['a range spanning a month boundary', 45],
    ['a range spanning a year boundary', 400],
  ])('counts both bounds for %s', (_, days) => {
    expect(dateRangeDayCount(rangeOf(days))).toBe(days);
  });

  // The options build their bounds at UTC midnight, so a count taken from local date parts
  // would come up a day short west of UTC.
  it('counts in UTC days regardless of the viewer timezone', () => {
    expect(
      dateRangeDayCount({
        startDate: new Date('2026-01-05T00:00:00.000Z'),
        endDate: new Date('2026-01-06T00:00:00.000Z'),
      }),
    ).toBe(2);
  });
});

describe('dateRangeGranularity', () => {
  it.each([
    ['a single day', 1, 'daily'],
    ['the last 7 days preset', 8, 'daily'],
    ['the last day of the daily band', 31, 'daily'],
    ['the first day of the weekly band', 32, 'weekly'],
    ['the last 90 days preset', 91, 'weekly'],
    ['the first day of the monthly band', 92, 'monthly'],
    ['the last 180 days preset', 181, 'monthly'],
  ])('buckets %s by %i days as %s', (_, days, expected) => {
    expect(dateRangeGranularity(rangeOf(days))).toBe(expected);
  });

  // The bands are read off the length alone, so a custom range no preset matches still lands
  // in one of them rather than falling through to a default.
  it.each([
    [14, 'daily'],
    [60, 'weekly'],
    [120, 'monthly'],
  ])('buckets a %i day custom range as %s', (days, expected) => {
    expect(dateRangeGranularity(rangeOf(days))).toBe(expected);
  });
});
