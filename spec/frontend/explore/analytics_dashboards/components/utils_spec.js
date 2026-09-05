import { resolveDateRangeFilter } from '~/explore/analytics_dashboards/components/utils';

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
