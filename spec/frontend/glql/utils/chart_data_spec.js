import {
  baseFieldKeyOf,
  labelWithParameter,
  dimensionLabelFormatter,
  dimensionValue,
  tooltipTitleFromParams,
  dimensionsOf,
  metricsOf,
  buildSeries,
  buildBarSeriesData,
  buildStackedByDimension,
  buildStackedByMetric,
  tooltipContentFromParams,
} from '~/glql/utils/chart_data';
import { DISPLAY_TYPES } from '~/glql/constants';

const LANGUAGE = { key: 'language', label: 'Language', name: 'language', type: 'dimension' };
const USER = { key: 'user', label: 'User', name: 'user', type: 'dimension' };
const CREATED = {
  key: 'created',
  label: 'Created',
  name: 'created',
  type: 'dimension',
  parameters: { granularity: 'daily' },
};
const TOTAL_COUNT = { key: 'totalCount', label: 'Total count', name: 'totalCount', type: 'metric' };
const ACCEPTANCE_RATE = {
  key: 'acceptanceRate',
  label: 'Acceptance rate',
  name: 'acceptanceRate',
  type: 'metric',
};
const DURATION_QUANTILE_P50 = {
  key: 'durationQuantile',
  field: 'durationQuantile',
  label: 'Duration quantile',
  type: 'metric',
  parameters: { quantile: 0.5 },
};

describe('dimensionsOf / metricsOf', () => {
  const ATTR = { key: 'state', label: 'State', name: 'state', type: 'attribute' };
  const fields = [LANGUAGE, TOTAL_COUNT, ATTR, USER, ACCEPTANCE_RATE];

  it('dimensionsOf returns only fields with type=dimension', () => {
    expect(dimensionsOf(fields)).toEqual([LANGUAGE, USER]);
  });

  it('metricsOf returns only fields with type=metric', () => {
    expect(metricsOf(fields)).toEqual([TOTAL_COUNT, ACCEPTANCE_RATE]);
  });

  it('returns empty arrays when no fields match', () => {
    expect(dimensionsOf([ATTR])).toEqual([]);
    expect(metricsOf([ATTR])).toEqual([]);
  });
});

describe('baseFieldKeyOf', () => {
  it('returns the field property when present (aliased field)', () => {
    expect(baseFieldKeyOf({ key: 'p50', field: 'durationQuantile' })).toBe('durationQuantile');
  });

  it('falls back to key when the field property is absent', () => {
    expect(baseFieldKeyOf({ key: 'totalCount' })).toBe('totalCount');
  });

  it('returns undefined for null input', () => {
    expect(baseFieldKeyOf(null)).toBeUndefined();
  });

  it('returns undefined for undefined input', () => {
    expect(baseFieldKeyOf(undefined)).toBeUndefined();
  });

  it('works with a full aliased field fixture', () => {
    const field = {
      key: 'p50',
      field: 'durationQuantile',
      label: 'Duration P50',
      type: 'metric',
      parameters: { quantile: 0.5 },
    };
    expect(baseFieldKeyOf(field)).toBe('durationQuantile');
  });
});

describe('labelWithParameter', () => {
  it('appends granularity in parentheses for a time dimension field', () => {
    const field = {
      key: 'finished',
      field: 'finished',
      label: 'Finished',
      name: 'finishedAt',
      type: 'dimension',
      parameters: { granularity: 'weekly' },
    };
    expect(labelWithParameter(field)).toBe('Finished (weekly)');
  });

  it('returns the plain label for a field without parameters', () => {
    expect(labelWithParameter(LANGUAGE)).toBe('Language');
  });

  it('returns the plain label for a field with empty parameters', () => {
    const field = { ...LANGUAGE, parameters: {} };
    expect(labelWithParameter(field)).toBe('Language');
  });

  it('handles monthly granularity', () => {
    const field = {
      key: 'created',
      field: 'created',
      label: 'Created',
      name: 'createdAt',
      type: 'dimension',
      parameters: { granularity: 'monthly' },
    };
    expect(labelWithParameter(field)).toBe('Created (monthly)');
  });

  it('appends non-granularity parameters for an unaliased field', () => {
    expect(labelWithParameter(DURATION_QUANTILE_P50)).toBe('Duration quantile (0.5)');
  });

  it('appends all parameter values when a field has multiple parameters', () => {
    const field = {
      key: 'durationQuantile',
      field: 'durationQuantile',
      label: 'Duration quantile',
      parameters: { quantile: 0.5, granularity: 'weekly' },
    };
    expect(labelWithParameter(field)).toBe('Duration quantile (0.5, weekly)');
  });

  it('ignores nullish parameter values', () => {
    const field = { ...LANGUAGE, parameters: { granularity: null } };
    expect(labelWithParameter(field)).toBe('Language');
  });

  it('returns the alias label as-is for an aliased time dimension field', () => {
    const field = {
      key: 'foo',
      field: 'created',
      label: 'foo',
      name: 'createdAt',
      type: 'dimension',
      parameters: { granularity: 'weekly' },
    };
    expect(labelWithParameter(field)).toBe('foo');
  });

  it('returns the alias label as-is for an aliased parameterised metric', () => {
    const field = {
      key: 'p50',
      field: 'durationQuantile',
      label: 'Duration P50',
      type: 'metric',
      parameters: { quantile: 0.5 },
    };
    expect(labelWithParameter(field)).toBe('Duration P50');
  });

  it('returns the plain label for a field with an identical name to the granularity', () => {
    const field = {
      key: 'finished',
      label: 'Weekly',
      name: 'finishedAt',
      type: 'dimension',
      parameters: { granularity: 'weekly' },
    };
    expect(labelWithParameter(field)).toBe('Weekly');
  });

  it('returns undefined for a field without a label even if a granularity exists', () => {
    const field = {
      key: 'finished',
      name: 'finishedAt',
      type: 'dimension',
      parameters: { granularity: 'weekly' },
    };
    expect(labelWithParameter(field)).toBeUndefined();
  });

  it('returns undefined for null input', () => {
    expect(labelWithParameter(null)).toBeUndefined();
  });

  it('returns undefined for undefined input', () => {
    expect(labelWithParameter(undefined)).toBeUndefined();
  });
});

describe('dimensionValue', () => {
  it('returns the value as-is for primitives', () => {
    expect(dimensionValue({ language: 'ruby' }, LANGUAGE)).toBe('ruby');
  });

  it('coerces numbers to strings', () => {
    expect(dimensionValue({ language: 42 }, LANGUAGE)).toBe('42');
  });

  it('returns "Unknown" when the value is null or undefined', () => {
    expect(dimensionValue({ language: null }, LANGUAGE)).toBe('Unknown');
    expect(dimensionValue({}, LANGUAGE)).toBe('Unknown');
  });

  it('formats UserCore values via the typename registry (name with username fallback)', () => {
    const userValue = { __typename: 'UserCore', name: 'I User1', username: 'i-user-1' };
    expect(dimensionValue({ language: userValue }, LANGUAGE)).toBe('I User1');
  });

  it('falls back to username when a UserCore value has no name', () => {
    const userValue = { __typename: 'UserCore', username: 'i-user-1' };
    expect(dimensionValue({ language: userValue }, LANGUAGE)).toBe('i-user-1');
  });

  it('formats Project values via nameWithNamespace', () => {
    const projectValue = {
      __typename: 'Project',
      fullPath: 'gitlab-org/gitlab',
      nameWithNamespace: 'GitLab Org / GitLab',
    };
    expect(dimensionValue({ language: projectValue }, LANGUAGE)).toBe('GitLab Org / GitLab');
  });

  it('falls back to fullPath, then name, when a Project has no nameWithNamespace', () => {
    expect(
      dimensionValue(
        { language: { __typename: 'Project', fullPath: 'gitlab-org/gitlab', name: 'GitLab' } },
        LANGUAGE,
      ),
    ).toBe('gitlab-org/gitlab');

    expect(dimensionValue({ language: { __typename: 'Project', name: 'GitLab' } }, LANGUAGE)).toBe(
      'GitLab',
    );
  });

  it('returns an empty label for object shapes without a registered formatter', () => {
    const value = { __typename: 'SomeUnregisteredType', title: 'whatever' };
    expect(dimensionValue({ language: value }, LANGUAGE)).toBe('');
  });

  // Time dimension bucket values pass through raw: dimensionValue's output
  // is the category/series identity downstream, so distinct buckets must
  // stay distinct even when their display labels would coincide. Display
  // formatting lives in dimensionLabelFormatter.
  it.each(['2026-01-01', '2026-08-03T00:00:00Z'])(
    'returns the bucket value %s unchanged for time dimensions',
    (value) => {
      expect(dimensionValue({ created: value }, CREATED)).toBe(value);
    },
  );

  it('passes date-shaped values through unchanged for non-time dimensions', () => {
    expect(dimensionValue({ language: '2026-01-01' }, LANGUAGE)).toBe('2026-01-01');
  });
});

describe('dimensionLabelFormatter', () => {
  const format = (granularity, value) =>
    dimensionLabelFormatter([{ created: value }], { ...CREATED, parameters: { granularity } })(
      value,
    );

  it.each`
    granularity  | value           | expected
    ${'daily'}   | ${'2026-06-01'} | ${'Jun 1'}
    ${'weekly'}  | ${'2026-01-12'} | ${'Jan 12 – 18'}
    ${'weekly'}  | ${'2026-06-29'} | ${'Jun 29 – Jul 5'}
    ${'monthly'} | ${'2026-06-01'} | ${'Jun 2026'}
    ${'yearly'}  | ${'2026-01-01'} | ${'2026'}
  `('formats a $granularity bucket start as $expected', ({ granularity, value, expected }) => {
    expect(format(granularity, value)).toBe(expected);
  });

  // Daily bucket starts arrive as ISO datetimes (ClickHouse's
  // toStartOfInterval returns DateTime for day intervals) while weekly and
  // monthly arrive date-only, so ISO datetime bucket values format too.
  it.each`
    granularity  | value                         | expected
    ${'daily'}   | ${'2026-08-03T00:00:00Z'}     | ${'Aug 3'}
    ${'daily'}   | ${'2026-08-03T00:00:00.000Z'} | ${'Aug 3'}
    ${'monthly'} | ${'2026-06-01T00:00:00Z'}     | ${'Jun 2026'}
  `('formats the ISO datetime bucket $value as $expected', ({ granularity, value, expected }) => {
    expect(format(granularity, value)).toBe(expected);
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
  ])('passes the non-bucket string %s through unchanged', (value) => {
    expect(format('daily', value)).toBe(value);
  });

  it('is plain stringification for non-time dimensions', () => {
    expect(dimensionLabelFormatter([], LANGUAGE)('2026-01-01')).toBe('2026-01-01');
    expect(dimensionLabelFormatter([], LANGUAGE)(42)).toBe('42');
  });
});

describe('multi-year time dimensions', () => {
  const DAILY = { ...CREATED, parameters: { granularity: 'daily' } };
  const WEEKLY = { ...CREATED, parameters: { granularity: 'weekly' } };
  const METRIC = { key: 'totalCount', label: 'Total count', type: 'metric' };
  const MULTI_YEAR_NODES = [
    { created: '2025-06-01', language: 'ruby', totalCount: 5 },
    { created: '2026-06-01', language: 'ruby', totalCount: 7 },
  ];

  // Bucket identity is the raw value, so same-day buckets from different
  // years can never merge, regardless of how they are labelled.
  it('buildStackedByDimension keeps same-day buckets from different years distinct', () => {
    const { groups, bars } = buildStackedByDimension({
      nodes: MULTI_YEAR_NODES,
      primaryDim: DAILY,
      secondaryDim: LANGUAGE,
      metric: METRIC,
    });

    expect(groups).toEqual(['2025-06-01', '2026-06-01']);
    expect(bars).toEqual([{ name: 'ruby', data: [5, 7] }]);
  });

  it('daily labels carry the year when buckets span multiple years', () => {
    const format = dimensionLabelFormatter(MULTI_YEAR_NODES, DAILY);

    expect(format('2025-06-01')).toBe('Jun 1, 2025');
    expect(format('2026-06-01')).toBe('Jun 1, 2026');
  });

  it('weekly labels carry the year when buckets span multiple years', () => {
    const nodes = [{ created: '2025-01-13' }, { created: '2026-12-28' }];
    const format = dimensionLabelFormatter(nodes, WEEKLY);

    expect(format('2025-01-13')).toBe('Jan 13 – 19, 2025');
    expect(format('2026-12-28')).toBe('Dec 28, 2026 – Jan 3, 2027');
  });

  it('includes years when a weekly bucket straddles the year boundary', () => {
    const nodes = [{ created: '2026-12-14' }, { created: '2026-12-28' }];
    const format = dimensionLabelFormatter(nodes, WEEKLY);

    expect(format('2026-12-14')).toBe('Dec 14 – 20, 2026');
    expect(format('2026-12-28')).toBe('Dec 28, 2026 – Jan 3, 2027');
  });

  it('labels stay compact when all buckets share one year', () => {
    const format = dimensionLabelFormatter(
      [{ created: '2026-06-01' }, { created: '2026-06-02' }],
      DAILY,
    );

    expect(format('2026-06-01')).toBe('Jun 1');
  });

  // Series/legend names have no formatting hook in ECharts, so the builder
  // bakes display labels into bars[].name through an injective mapping while
  // grouping stays keyed by the raw value.
  it('keeps same-day buckets from different years distinct as series names', () => {
    const { groups, bars } = buildStackedByDimension({
      nodes: [
        { language: 'ruby', created: '2025-06-01', totalCount: 5 },
        { language: 'ruby', created: '2026-06-01', totalCount: 7 },
      ],
      primaryDim: LANGUAGE,
      secondaryDim: DAILY,
      metric: METRIC,
    });

    expect(groups).toEqual(['ruby']);
    expect(bars).toEqual([
      { name: 'Jun 1, 2025', data: [5] },
      { name: 'Jun 1, 2026', data: [7] },
    ]);
  });

  it('falls back to raw values as series names when labels collide', () => {
    const { bars } = buildStackedByDimension({
      nodes: [
        { language: 'ruby', created: '2026-06-01', totalCount: 5 },
        { language: 'ruby', created: '2026-06-01T00:00:00Z', totalCount: 7 },
      ],
      primaryDim: LANGUAGE,
      secondaryDim: DAILY,
      metric: METRIC,
    });

    expect(bars.map((b) => b.name)).toEqual(['2026-06-01', '2026-06-01T00:00:00Z']);
  });

  it('formats time dimension series names when it is the secondary dimension', () => {
    const { bars } = buildStackedByDimension({
      nodes: [
        { language: 'ruby', created: '2026-06-01', totalCount: 5 },
        { language: 'ruby', created: '2026-07-01', totalCount: 7 },
      ],
      primaryDim: LANGUAGE,
      secondaryDim: { ...CREATED, parameters: { granularity: 'monthly' } },
      metric: METRIC,
    });

    expect(bars.map((b) => b.name)).toEqual(['Jun 2026', 'Jul 2026']);
  });
});

describe('tooltipTitleFromParams', () => {
  const formatLabel = (v) => `L(${v})`;

  it('formats deduplicated tuple categories for column and line charts', () => {
    const params = {
      seriesData: [{ value: ['2026-06-01', 5] }, { value: ['2026-06-01', 7] }],
    };

    expect(tooltipTitleFromParams(params, { formatLabel })).toBe('L(2026-06-01)');
  });

  it('reads the flipped tuple index for bar charts', () => {
    const params = { seriesData: [{ value: [5, '2026-06-01'] }] };

    expect(
      tooltipTitleFromParams(params, { formatLabel, displayType: DISPLAY_TYPES.BAR_CHART }),
    ).toBe('L(2026-06-01)');
  });

  it('falls back to the point name for scalar stacked-column values', () => {
    const params = { seriesData: [{ value: 5, name: '2026-06-01' }] };

    expect(tooltipTitleFromParams(params, { formatLabel })).toBe('L(2026-06-01)');
  });

  it('appends the axis name and handles missing params', () => {
    const params = { seriesData: [{ value: ['ruby', 5] }] };

    expect(tooltipTitleFromParams(params, { axisName: 'Language' })).toBe('ruby (Language)');
    expect(tooltipTitleFromParams(null)).toBe('');
  });
});

describe('buildSeries', () => {
  it('builds a single series of [dimension, metric] tuples', () => {
    const nodes = [
      { language: 'ruby', totalCount: 21 },
      { language: 'python', totalCount: 14 },
    ];

    expect(buildSeries(nodes, LANGUAGE, TOTAL_COUNT)).toEqual([
      {
        name: 'Total count',
        data: [
          ['ruby', 21],
          ['python', 14],
        ],
      },
    ]);
  });

  it('defaults missing metric values to 0', () => {
    const nodes = [{ language: 'ruby' }];
    expect(buildSeries(nodes, LANGUAGE, TOTAL_COUNT)[0].data).toEqual([['ruby', 0]]);
  });

  it('names the series with the parameterised label for an unaliased parameterised metric', () => {
    const nodes = [{ language: 'ruby', durationQuantile: 3661 }];

    expect(buildSeries(nodes, LANGUAGE, DURATION_QUANTILE_P50)).toEqual([
      { name: 'Duration quantile (0.5)', data: [['ruby', 3661]] },
    ]);
  });

  it('names the series with the alias label for an aliased parameterised metric', () => {
    const aliased = {
      key: 'p50',
      field: 'durationQuantile',
      label: 'Duration P50',
      type: 'metric',
      parameters: { quantile: 0.5 },
    };
    const nodes = [{ language: 'ruby', p50: 3661 }];

    expect(buildSeries(nodes, LANGUAGE, aliased)).toEqual([
      { name: 'Duration P50', data: [['ruby', 3661]] },
    ]);
  });

  it.each([
    { scenario: 'empty nodes', nodes: [], dim: LANGUAGE, metric: TOTAL_COUNT },
    {
      scenario: 'missing dimension',
      nodes: [{ language: 'ruby', totalCount: 1 }],
      dim: null,
      metric: TOTAL_COUNT,
    },
    {
      scenario: 'missing metric',
      nodes: [{ language: 'ruby', totalCount: 1 }],
      dim: LANGUAGE,
      metric: null,
    },
  ])('returns an empty array with $scenario', ({ nodes, dim, metric }) => {
    expect(buildSeries(nodes, dim, metric)).toEqual([]);
  });
});

describe('buildBarSeriesData', () => {
  it('builds an object keyed by metric label with reversed [value, dimension] tuples', () => {
    const nodes = [
      { language: 'ruby', totalCount: 21 },
      { language: 'python', totalCount: 14 },
    ];

    expect(buildBarSeriesData(nodes, LANGUAGE, [TOTAL_COUNT])).toEqual({
      'Total count': [
        [21, 'ruby'],
        [14, 'python'],
      ],
    });
  });

  it('builds one entry per metric', () => {
    const nodes = [{ language: 'ruby', totalCount: 21, acceptanceRate: 0.625 }];

    expect(buildBarSeriesData(nodes, LANGUAGE, [TOTAL_COUNT, ACCEPTANCE_RATE])).toEqual({
      'Total count': [[21, 'ruby']],
      'Acceptance rate': [[0.625, 'ruby']],
    });
  });

  it('defaults missing metric values to 0', () => {
    const nodes = [{ language: 'ruby' }];
    expect(buildBarSeriesData(nodes, LANGUAGE, [TOTAL_COUNT])).toEqual({
      'Total count': [[0, 'ruby']],
    });
  });

  it('keys an unaliased parameterised metric by its parameterised label', () => {
    const nodes = [{ language: 'ruby', durationQuantile: 3661 }];

    expect(buildBarSeriesData(nodes, LANGUAGE, [DURATION_QUANTILE_P50])).toEqual({
      'Duration quantile (0.5)': [[3661, 'ruby']],
    });
  });

  it.each([
    { scenario: 'empty nodes', nodes: [], dim: LANGUAGE, metrics: [TOTAL_COUNT] },
    {
      scenario: 'missing dimension',
      nodes: [{ language: 'ruby' }],
      dim: null,
      metrics: [TOTAL_COUNT],
    },
    { scenario: 'empty metrics', nodes: [{ language: 'ruby' }], dim: LANGUAGE, metrics: [] },
  ])('returns an empty object with $scenario', ({ nodes, dim, metrics }) => {
    expect(buildBarSeriesData(nodes, dim, metrics)).toEqual({});
  });
});

describe('buildStackedByDimension', () => {
  it('builds groups and bars keyed by the secondary dimension', () => {
    const nodes = [
      { user: 'u0', language: 'ruby', totalCount: 12 },
      { user: 'u0', language: 'python', totalCount: 6 },
      { user: 'u2', language: 'ruby', totalCount: 6 },
      { user: 'u2', language: 'python', totalCount: 5 },
    ];

    expect(
      buildStackedByDimension({
        nodes,
        primaryDim: USER,
        secondaryDim: LANGUAGE,
        metric: TOTAL_COUNT,
      }),
    ).toEqual({
      groups: ['u0', 'u2'],
      bars: [
        { name: 'ruby', data: [12, 6] },
        { name: 'python', data: [6, 5] },
      ],
    });
  });

  it('pads missing (primary, secondary) combinations with 0 to keep bars aligned', () => {
    const nodes = [
      { user: 'u0', language: 'ruby', totalCount: 12 },
      { user: 'u2', language: 'python', totalCount: 5 },
    ];

    expect(
      buildStackedByDimension({
        nodes,
        primaryDim: USER,
        secondaryDim: LANGUAGE,
        metric: TOTAL_COUNT,
      }),
    ).toEqual({
      groups: ['u0', 'u2'],
      bars: [
        { name: 'ruby', data: [12, 0] },
        { name: 'python', data: [0, 5] },
      ],
    });
  });

  it('keeps raw date-bucket primary dimension values as group identities', () => {
    const nodes = [
      { created: '2026-01-01', language: 'ruby', totalCount: 12 },
      { created: '2026-02-01', language: 'ruby', totalCount: 6 },
    ];

    expect(
      buildStackedByDimension({
        nodes,
        primaryDim: CREATED,
        secondaryDim: LANGUAGE,
        metric: TOTAL_COUNT,
      }),
    ).toEqual({
      groups: ['2026-01-01', '2026-02-01'],
      bars: [{ name: 'ruby', data: [12, 6] }],
    });
  });

  it.each([
    {
      scenario: 'empty nodes',
      nodes: [],
      primaryDim: USER,
      secondaryDim: LANGUAGE,
      metric: TOTAL_COUNT,
    },
    {
      scenario: 'missing primary dim',
      nodes: [{}],
      primaryDim: null,
      secondaryDim: LANGUAGE,
      metric: TOTAL_COUNT,
    },
    {
      scenario: 'missing secondary dim',
      nodes: [{}],
      primaryDim: USER,
      secondaryDim: null,
      metric: TOTAL_COUNT,
    },
    {
      scenario: 'missing metric',
      nodes: [{}],
      primaryDim: USER,
      secondaryDim: LANGUAGE,
      metric: null,
    },
  ])(
    'returns empty groups and bars with $scenario',
    ({ nodes, primaryDim, secondaryDim, metric }) => {
      expect(buildStackedByDimension({ nodes, primaryDim, secondaryDim, metric })).toEqual({
        groups: [],
        bars: [],
      });
    },
  );
});

describe('buildStackedByMetric', () => {
  it('builds groups from the dimension and one bar series per metric', () => {
    const nodes = [
      { language: 'ruby', totalCount: 21, acceptanceRate: 0.625 },
      { language: 'python', totalCount: 14, acceptanceRate: 0.333 },
    ];

    expect(buildStackedByMetric(nodes, LANGUAGE, [TOTAL_COUNT, ACCEPTANCE_RATE])).toEqual({
      groups: ['ruby', 'python'],
      bars: [
        { name: 'Total count', data: [21, 14] },
        { name: 'Acceptance rate', data: [0.625, 0.333] },
      ],
    });
  });

  it('names the bar series with the parameterised label for an unaliased parameterised metric', () => {
    const nodes = [{ language: 'ruby', durationQuantile: 3661 }];

    expect(buildStackedByMetric(nodes, LANGUAGE, [DURATION_QUANTILE_P50])).toEqual({
      groups: ['ruby'],
      bars: [{ name: 'Duration quantile (0.5)', data: [3661] }],
    });
  });

  it.each([
    { scenario: 'empty nodes', nodes: [], dim: LANGUAGE, metrics: [TOTAL_COUNT] },
    { scenario: 'missing dimension', nodes: [{}], dim: null, metrics: [TOTAL_COUNT] },
    { scenario: 'empty metrics', nodes: [{}], dim: LANGUAGE, metrics: [] },
  ])('returns empty groups and bars with $scenario', ({ nodes, dim, metrics }) => {
    expect(buildStackedByMetric(nodes, dim, metrics)).toEqual({ groups: [], bars: [] });
  });
});

describe('tooltipContentFromParams', () => {
  it('returns an empty object when params is missing', () => {
    expect(tooltipContentFromParams(null)).toEqual({});
    expect(tooltipContentFromParams(undefined)).toEqual({});
    expect(tooltipContentFromParams({})).toEqual({});
  });

  it('extracts the numeric value from [label, num] tuples (column chart shape)', () => {
    const params = {
      seriesData: [
        { seriesName: 'Success rate', value: ['ruby', 0.819], color: '#aaa' },
        { seriesName: 'Duration quantile', value: ['ruby', 5380], color: '#bbb' },
      ],
    };

    expect(tooltipContentFromParams(params)).toEqual({
      'Success rate': { value: 0.819, color: '#aaa' },
      'Duration quantile': { value: 5380, color: '#bbb' },
    });
  });

  it('extracts the numeric value from [num, label] tuples when displayType is barChart', () => {
    const params = {
      seriesData: [
        { seriesName: 'Success rate', value: [0.819, 'ruby'], color: '#aaa' },
        { seriesName: 'Duration quantile', value: [5380, 'ruby'], color: '#bbb' },
      ],
    };

    expect(tooltipContentFromParams(params, DISPLAY_TYPES.BAR_CHART)).toEqual({
      'Success rate': { value: 0.819, color: '#aaa' },
      'Duration quantile': { value: 5380, color: '#bbb' },
    });
  });

  it('defaults to the [label, num] shape for other display types', () => {
    const params = {
      seriesData: [{ seriesName: 'Total count', value: ['ruby', 21], color: '#aaa' }],
    };

    expect(tooltipContentFromParams(params, DISPLAY_TYPES.LINE_CHART)).toEqual({
      'Total count': { value: 21, color: '#aaa' },
    });
  });

  it('passes scalar values through unchanged (stacked chart shape)', () => {
    const params = {
      seriesData: [
        { seriesName: 'Success rate', value: 0.819, color: '#aaa' },
        { seriesName: 'Duration quantile', value: 5380, color: '#bbb' },
        { seriesName: 'Total count', value: 2568670, color: '#ccc' },
      ],
    };

    expect(tooltipContentFromParams(params)).toEqual({
      'Success rate': { value: 0.819, color: '#aaa' },
      'Duration quantile': { value: 5380, color: '#bbb' },
      'Total count': { value: 2568670, color: '#ccc' },
    });
  });

  it('prefers borderColor over color when both are present', () => {
    const params = {
      seriesData: [{ seriesName: 'A', value: 1, color: '#aaa', borderColor: '#bbb' }],
    };

    expect(tooltipContentFromParams(params).A.color).toBe('#bbb');
  });

  it('coerces missing values to 0 to avoid NaN in formatted output', () => {
    const params = {
      seriesData: [
        { seriesName: 'scalar undefined', value: undefined, color: '#aaa' },
        { seriesName: 'scalar null', value: null, color: '#bbb' },
        { seriesName: 'tuple missing num', value: ['ruby', undefined], color: '#ccc' },
      ],
    };

    expect(tooltipContentFromParams(params)).toEqual({
      'scalar undefined': { value: 0, color: '#aaa' },
      'scalar null': { value: 0, color: '#bbb' },
      'tuple missing num': { value: 0, color: '#ccc' },
    });
  });
});
