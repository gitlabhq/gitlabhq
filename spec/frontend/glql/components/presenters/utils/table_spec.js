import {
  resolveTrendField,
  trendColumnFor,
  withTrendColumn,
} from '~/glql/components/presenters/utils/table';
import { TREND_CHANGE_KEY, TREND_KEY } from '~/glql/components/presenters/utils/trend';

const mockLanguageDimension = { key: 'language', label: 'Language', type: 'dimension' };
const mockTotalCountMetric = { key: 'totalCount', label: 'Total count', type: 'metric' };

describe('resolveTrendField', () => {
  const mockAliasedMetric = { key: 'Suggestions', field: 'totalCount', type: 'metric' };
  const mockAcceptanceRateMetric = { key: 'acceptanceRate', type: 'metric' };

  it('defaults to the only metric when none is named', () => {
    expect(resolveTrendField([mockTotalCountMetric], '')).toEqual({
      field: mockTotalCountMetric,
      error: null,
    });
  });

  it('resolves to nothing when there is no metric to compare', () => {
    expect(resolveTrendField([], '')).toEqual({ field: null, error: null });
  });

  it.each(['Suggestions', 'totalCount'])('matches `%s` on the alias or the base key', (metric) => {
    expect(resolveTrendField([mockAliasedMetric, mockAcceptanceRateMetric], metric)).toEqual({
      field: mockAliasedMetric,
      error: null,
    });
  });

  it('reports an error when several metrics are selected and none is named', () => {
    expect(resolveTrendField([mockTotalCountMetric, mockAcceptanceRateMetric], '')).toEqual({
      field: null,
      error: 'table display type requires `trendMetric` when several metrics are selected',
    });
  });

  it('reports an error when the named metric is not selected', () => {
    expect(resolveTrendField([mockTotalCountMetric], 'usersCount')).toEqual({
      field: null,
      error: 'Unknown metric for `trendMetric`: `usersCount`.',
    });
  });
});

describe('trendColumnFor', () => {
  const mockFields = [mockLanguageDimension, mockTotalCountMetric];
  const mockData = {
    nodes: [
      { language: 'ruby', totalCount: 21 },
      { language: 'go', totalCount: 10 },
    ],
  };
  const mockComparisonData = { nodes: [{ language: 'ruby', totalCount: 20 }] };

  const build = (overrides = {}) =>
    trendColumnFor({
      fields: mockFields,
      data: mockData,
      comparisonData: mockComparisonData,
      metric: mockTotalCountMetric,
      source: 'CodeSuggestions',
      ...overrides,
    });

  it('renders the badge config but sorts by the change', () => {
    expect(build().column).toEqual({
      key: '__trend',
      sortKey: '__trendChange',
      label: 'vs previous period',
      type: 'metric',
    });
  });

  it('builds a badge for a row that pairs, without the "vs prior" suffix', () => {
    const [ruby] = build().rows;

    expect(ruby[TREND_CHANGE_KEY]).toBe(0.05);
    expect(ruby[TREND_KEY]).toMatchObject({
      __typename: '__Trend',
      text: '5%',
      variant: 'success',
    });
  });

  it('gives a row with no counterpart an empty, non-null trend and a null change', () => {
    const [, go] = build().rows;

    expect(go[TREND_KEY]).toEqual({ __typename: '__Trend' });
    expect(go[TREND_CHANGE_KEY]).toBe(null);
  });

  it.each([
    ['there is no metric', { metric: null }],
    ['there is no comparison data', { comparisonData: null }],
    ['the previous period returned no rows', { comparisonData: { nodes: [] } }],
    [
      'a dimension buckets by date',
      {
        fields: [
          { key: 'created', type: 'dimension', parameters: { granularity: 'weekly' } },
          mockTotalCountMetric,
        ],
      },
    ],
  ])('is null when %s', (_, overrides) => {
    expect(build(overrides)).toBe(null);
  });

  it('reserves an unsortable column with pending trends while the comparison is running', () => {
    const { column, rows } = build({ comparisonData: null, pending: true });

    expect(column).toMatchObject({ key: '__trend', sortable: false });
    expect(rows.map((row) => row[TREND_KEY])).toEqual([
      { __typename: '__Trend', pending: true },
      { __typename: '__Trend', pending: true },
    ]);
  });
});

describe('withTrendColumn', () => {
  const mockFields = [mockLanguageDimension, mockTotalCountMetric];
  const mockData = { nodes: [{ language: 'ruby', totalCount: 21 }] };
  const mockComparisonData = { nodes: [{ language: 'ruby', totalCount: 20 }] };

  const build = (overrides = {}) =>
    withTrendColumn({
      fields: mockFields,
      data: mockData,
      comparisonData: mockComparisonData,
      source: 'CodeSuggestions',
      ...overrides,
    });

  it('returns the input untouched without comparison data', () => {
    expect(build({ comparisonData: null })).toEqual({
      fields: mockFields,
      data: mockData,
      error: null,
    });
  });

  it('appends the trend column and the trend values to the rows', () => {
    const { fields, data, error } = build();

    expect(fields.map(({ key }) => key)).toEqual(['language', 'totalCount', '__trend']);
    expect(data.nodes[0]).toMatchObject({ language: 'ruby', [TREND_CHANGE_KEY]: 0.05 });
    expect(error).toBe(null);
  });

  it('compares the metric the comparison result names', () => {
    const mockUsersMetric = { key: 'usersCount', label: 'Users', type: 'metric' };

    const { data } = build({
      fields: [...mockFields, mockUsersMetric],
      data: { nodes: [{ language: 'ruby', totalCount: 21, usersCount: 6 }] },
      comparisonData: {
        metric: 'usersCount',
        nodes: [{ language: 'ruby', totalCount: 20, usersCount: 4 }],
      },
    });

    expect(data.nodes[0][TREND_CHANGE_KEY]).toBe(0.5);
  });

  it('reports a trendMetric it cannot resolve, and adds no column', () => {
    const { fields, error } = build({
      comparisonData: { ...mockComparisonData, metric: 'usersCount' },
    });

    expect(fields).toBe(mockFields);
    expect(error).toBe('Unknown metric for `trendMetric`: `usersCount`.');
  });
});
