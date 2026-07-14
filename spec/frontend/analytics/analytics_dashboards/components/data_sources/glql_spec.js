import fetch from '~/analytics/analytics_dashboards/data_sources/glql';

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
});
