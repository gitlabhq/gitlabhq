import fetch from '~/analytics/analytics_dashboards/data_sources/glql';

// The panel declares where the dashboard's date range belongs, because only the query
// knows which field to filter on.
const DATED_QUERY =
  'type = AiUsageEvent and timestamp >= "%{startDate}" and timestamp <= "%{endDate}"';

describe('GLQL data source', () => {
  it('returns the query string from the panel query', () => {
    expect(fetch({ query: { glql: 'type = Issue AND state = opened' } })).toBe(
      'type = Issue AND state = opened',
    );
  });

  it('returns an empty string when the query is missing', () => {
    expect(fetch({ query: {} })).toBe('');
  });

  it('returns an empty string when no arguments are provided', () => {
    expect(fetch()).toBe('');
  });

  it('throws when the query is not a string', () => {
    expect(() => fetch({ query: { glql: { some: 'object' } } })).toThrow(
      'GLQL query must be a string.',
    );
  });

  describe('date range filter', () => {
    const fetchDated = (filters) => fetch({ query: { glql: DATED_QUERY }, filters });

    it('resolves the placeholders from the selected option', () => {
      expect(fetchDated({ dateRangeOption: '7d' })).toBe(
        'type = AiUsageEvent and timestamp >= "2020-06-29" and timestamp <= "2020-07-06"',
      );
    });

    it.each([
      ['no filters at all', undefined],
      ['an empty filter set', {}],
      ['an unknown option', { dateRangeOption: 'last-fortnight' }],
    ])('falls back to the last 30 days given %s', (_, filters) => {
      expect(fetchDated(filters)).toBe(
        'type = AiUsageEvent and timestamp >= "2020-06-06" and timestamp <= "2020-07-06"',
      );
    });

    it('takes the dates the filter supplies for a custom range', () => {
      const filters = {
        dateRangeOption: 'custom',
        startDate: new Date(Date.UTC(2026, 0, 5)),
        endDate: new Date(Date.UTC(2026, 2, 31)),
      };

      expect(fetchDated(filters)).toBe(
        'type = AiUsageEvent and timestamp >= "2026-01-05" and timestamp <= "2026-03-31"',
      );
    });

    // `custom` carries no dates of its own, and an unsubstituted placeholder would reach
    // the GLQL compiler as a literal and fail the panel. The picker emits the bounds one at
    // a time, so taking a start without an end would stretch the window to today, and an end
    // without a start would run it backwards.
    it.each([
      ['no dates', {}],
      ['only a start date', { startDate: new Date(Date.UTC(2026, 0, 5)) }],
      ['only an end date', { endDate: new Date(Date.UTC(2026, 2, 31)) }],
    ])('falls back to the last 30 days for a custom range with %s', (_, dates) => {
      expect(fetchDated({ dateRangeOption: 'custom', ...dates })).toBe(
        'type = AiUsageEvent and timestamp >= "2020-06-06" and timestamp <= "2020-07-06"',
      );
    });

    it('substitutes an open-ended range that sets only a start', () => {
      const glql = 'type = AiUsageEvent and timestamp >= "%{startDate}"';

      expect(fetch({ query: { glql }, filters: { dateRangeOption: '7d' } })).toBe(
        'type = AiUsageEvent and timestamp >= "2020-06-29"',
      );
    });

    it('substitutes every occurrence of a placeholder', () => {
      const glql = 'created >= "%{startDate}" and merged >= "%{startDate}"';

      expect(fetch({ query: { glql }, filters: { dateRangeOption: '7d' } })).toBe(
        'created >= "2020-06-29" and merged >= "2020-06-29"',
      );
    });

    it('leaves a query without placeholders untouched', () => {
      const glql = 'type = AiUsageEvent and timestamp >= -30d';

      expect(fetch({ query: { glql }, filters: { dateRangeOption: '7d' } })).toBe(glql);
    });

    it('leaves a placeholder it does not know how to resolve alone', () => {
      const glql = 'author = "%{currentUser}" and timestamp >= "%{startDate}"';

      expect(fetch({ query: { glql }, filters: { dateRangeOption: '7d' } })).toBe(
        'author = "%{currentUser}" and timestamp >= "2020-06-29"',
      );
    });
  });
});
