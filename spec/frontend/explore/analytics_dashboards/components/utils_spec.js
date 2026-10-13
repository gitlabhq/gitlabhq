import {
  dateRangeDayCount,
  dateRangeFilterFromQuery,
  dateRangeFilterToQueryParams,
  dateRangeFilterToUtc,
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
    expect(resolveDateRangeFilter()).toMatchObject(LAST_30_DAYS);
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

describe('dateRangeFilterFromQuery', () => {
  it('resolves a named option to its own window', () => {
    expect(dateRangeFilterFromQuery('?date_range=30d')).toEqual({
      dateRangeOption: '30d',
      startDate: new Date('2020-06-06T00:00:00.000Z'),
      endDate: new Date('2020-07-06T00:00:00.000Z'),
    });
  });

  it.each([
    ['the query string names no option', '?scope=gitlab-org'],
    ['the query string is empty', ''],
    ['the option is not a date range at all', '?date_range=last-fortnight'],
  ])('returns null when %s', (_, queryString) => {
    expect(dateRangeFilterFromQuery(queryString)).toBeNull();
  });

  it('returns null for an option the dashboard does not offer', () => {
    expect(dateRangeFilterFromQuery('?date_range=365d', { options: ['7d', '30d'] })).toBeNull();
  });

  it('resolves an option the dashboard does offer', () => {
    expect(dateRangeFilterFromQuery('?date_range=7d', { options: ['7d', '30d'] })).toMatchObject({
      dateRangeOption: '7d',
    });
  });

  describe('a custom range', () => {
    it('takes both bounds from the query string', () => {
      const filter = dateRangeFilterFromQuery(
        '?date_range=custom&start_date=2020-05-05&end_date=2020-06-30',
      );

      expect(filter.dateRangeOption).toBe('custom');
      expect(filter.startDate.toISOString()).toBe('2020-05-05T00:00:00.000Z');
      expect(filter.endDate.toISOString()).toBe('2020-06-30T00:00:00.000Z');
    });

    it.each([
      ['neither bound', '?date_range=custom'],
      ['only a start', '?date_range=custom&start_date=2020-05-05'],
      ['only an end', '?date_range=custom&end_date=2020-06-30'],
      ['an unparseable bound', '?date_range=custom&start_date=whenever&end_date=2020-06-30'],
      ['invalid bounds', '?date_range=custom&start_date=2020-06-30&end_date=2020-05-05'],
      [
        'a bound that is not a plain date',
        '?date_range=custom&start_date=2020-05-05T12:00:00Z&end_date=2020-06-30',
      ],
    ])('returns null given %s', (_, queryString) => {
      expect(dateRangeFilterFromQuery(queryString)).toBeNull();
    });

    // The picker cannot reach past today, so a link is the only way to a window that does.
    it('takes a range ending today', () => {
      expect(
        dateRangeFilterFromQuery('?date_range=custom&start_date=2020-07-01&end_date=2020-07-06'),
      ).toMatchObject({ dateRangeOption: 'custom' });
    });

    it('returns null for a range ending after today', () => {
      expect(
        dateRangeFilterFromQuery('?date_range=custom&start_date=2020-07-01&end_date=2020-07-07'),
      ).toBeNull();
    });

    // Both bounds count towards the limit, the way the picker measures a range, so a window
    // of exactly the limit sits on it rather than one day past it.
    it('takes a range on the day limit', () => {
      expect(
        dateRangeFilterFromQuery('?date_range=custom&start_date=2020-06-01&end_date=2020-07-01', {
          daysLimit: 31,
        }),
      ).toMatchObject({ dateRangeOption: 'custom' });
    });

    it('returns null for a range past the day limit', () => {
      expect(
        dateRangeFilterFromQuery('?date_range=custom&start_date=2020-06-01&end_date=2020-07-02', {
          daysLimit: 31,
        }),
      ).toBeNull();
    });
  });
});

describe('dateRangeFilterToQueryParams', () => {
  it('names the selected option', () => {
    expect(dateRangeFilterToQueryParams({ dateRangeOption: '30d' })).toEqual({
      date_range: '30d',
      start_date: null,
      end_date: null,
    });
  });

  it('drops the bounds a named option came with', () => {
    expect(
      dateRangeFilterToQueryParams({
        dateRangeOption: '30d',
        startDate: new Date('2026-01-05T00:00:00.000Z'),
        endDate: new Date('2026-03-31T00:00:00.000Z'),
      }),
    ).toMatchObject({ start_date: null, end_date: null });
  });

  it('writes both bounds for a custom range', () => {
    expect(
      dateRangeFilterToQueryParams({
        dateRangeOption: 'custom',
        startDate: new Date('2026-01-05T00:00:00.000Z'),
        endDate: new Date('2026-03-31T00:00:00.000Z'),
      }),
    ).toEqual({
      date_range: 'custom',
      start_date: '2026-01-05',
      end_date: '2026-03-31',
    });
  });

  it.each([
    ['no bounds', {}],
    ['only a start', { startDate: new Date('2026-01-05T00:00:00.000Z') }],
    ['only an end', { endDate: new Date('2026-03-31T00:00:00.000Z') }],
  ])('writes no bounds for a custom range with %s', (_, dates) => {
    expect(dateRangeFilterToQueryParams({ dateRangeOption: 'custom', ...dates })).toEqual({
      date_range: 'custom',
      start_date: null,
      end_date: null,
    });
  });

  it('nulls every param given nothing', () => {
    expect(dateRangeFilterToQueryParams()).toEqual({
      date_range: null,
      start_date: null,
      end_date: null,
    });
  });
});

describe('dateRangeFilterToUtc', () => {
  it('takes the day a custom range names to UTC midnight', () => {
    expect(
      dateRangeFilterToUtc({
        dateRangeOption: 'custom',
        startDate: new Date('2026-01-05T13:45:00.000Z'),
        endDate: new Date('2026-03-31T13:45:00.000Z'),
        groups: ['gitlab-org'],
      }),
    ).toEqual({
      dateRangeOption: 'custom',
      startDate: new Date('2026-01-05T00:00:00.000Z'),
      endDate: new Date('2026-03-31T00:00:00.000Z'),
      groups: ['gitlab-org'],
    });
  });

  // A named option builds its bounds at UTC midnight already, so reading them as local days
  // would move the window west of UTC.
  it('passes a named option through untouched', () => {
    const filter = { dateRangeOption: '30d', ...LAST_30_DAYS };

    expect(dateRangeFilterToUtc(filter)).toBe(filter);
  });

  it('returns an empty filter given nothing', () => {
    expect(dateRangeFilterToUtc()).toEqual({});
  });
});
