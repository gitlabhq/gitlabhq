import {
  dimensionValue,
  dimensionsOf,
  metricsOf,
  buildSeries,
  buildStackedByDimension,
  buildStackedByMetric,
} from '~/glql/utils/chart_data';

const LANGUAGE = { key: 'language', label: 'Language', name: 'language', type: 'dimension' };
const USER = { key: 'user', label: 'User', name: 'user', type: 'dimension' };
const TOTAL_COUNT = { key: 'totalCount', label: 'Total count', name: 'totalCount', type: 'metric' };
const ACCEPTANCE_RATE = {
  key: 'acceptanceRate',
  label: 'Acceptance rate',
  name: 'acceptanceRate',
  type: 'metric',
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

  it('returns an empty label for object shapes without a registered formatter', () => {
    const value = { __typename: 'SomeUnregisteredType', title: 'whatever' };
    expect(dimensionValue({ language: value }, LANGUAGE)).toBe('');
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

  it.each([
    { scenario: 'empty nodes', nodes: [], dim: LANGUAGE, metrics: [TOTAL_COUNT] },
    { scenario: 'missing dimension', nodes: [{}], dim: null, metrics: [TOTAL_COUNT] },
    { scenario: 'empty metrics', nodes: [{}], dim: LANGUAGE, metrics: [] },
  ])('returns empty groups and bars with $scenario', ({ nodes, dim, metrics }) => {
    expect(buildStackedByMetric(nodes, dim, metrics)).toEqual({ groups: [], bars: [] });
  });
});
