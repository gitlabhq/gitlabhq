import {
  formatCount,
  formatCountCompact,
  formatRate,
  formatDuration,
  formatDurationCompact,
  formatterFor,
  axisFormatterFor,
  unitFor,
  labelForUnit,
  buildFormatterByLabel,
  buildSharedAxisFormatter,
  formatValueForLabel,
  yAxisTitleFor,
} from '~/glql/utils/value_format';

describe('formatCount', () => {
  it.each`
    value      | expected
    ${0}       | ${'0'}
    ${42}      | ${'42'}
    ${1000}    | ${'1,000'}
    ${1234567} | ${'1,234,567'}
  `('formats $value as $expected', ({ value, expected }) => {
    expect(formatCount(value)).toBe(expected);
  });
});

describe('formatCountCompact', () => {
  it.each`
    value      | expected
    ${0}       | ${'0'}
    ${42}      | ${'42'}
    ${999}     | ${'999'}
    ${1000}    | ${'1K'}
    ${1500}    | ${'1.5K'}
    ${1234}    | ${'1.2K'}
    ${1234567} | ${'1.2M'}
    ${2500000} | ${'2.5M'}
  `('formats $value as $expected', ({ value, expected }) => {
    expect(formatCountCompact(value)).toBe(expected);
  });
});

describe('formatRate', () => {
  it.each`
    value     | expected
    ${0}      | ${'0%'}
    ${1}      | ${'100%'}
    ${0.5}    | ${'50%'}
    ${0.425}  | ${'42.5%'}
    ${0.001}  | ${'0.1%'}
    ${0.9875} | ${'98.8%'}
  `('formats $value as $expected', ({ value, expected }) => {
    expect(formatRate(value)).toBe(expected);
  });
});

describe('formatDuration', () => {
  it.each`
    seconds  | expected
    ${0}     | ${'0s'}
    ${30}    | ${'30s'}
    ${60}    | ${'1m'}
    ${90}    | ${'1m 30s'}
    ${3600}  | ${'1h'}
    ${3661}  | ${'1h 1m 1s'}
    ${86400} | ${'1d'}
  `('formats $seconds seconds as $expected', ({ seconds, expected }) => {
    expect(formatDuration(seconds)).toBe(expected);
  });
});

describe('formatDurationCompact', () => {
  it.each`
    seconds  | expected
    ${0}     | ${'0s'}
    ${30}    | ${'30s'}
    ${60}    | ${'1min'}
    ${90}    | ${'1.5min'}
    ${2000}  | ${'33.3min'}
    ${3600}  | ${'1h'}
    ${3661}  | ${'1h'}
    ${10000} | ${'2.8h'}
    ${86400} | ${'1d'}
  `('formats $seconds seconds as $expected', ({ seconds, expected }) => {
    expect(formatDurationCompact(seconds)).toBe(expected);
  });
});

describe('formatterFor', () => {
  it.each`
    fieldKey               | input     | expected
    ${'totalCount'}        | ${1234}   | ${'1,234'}
    ${'usersCount'}        | ${42}     | ${'42'}
    ${'shownCount'}        | ${1801}   | ${'1,801'}
    ${'acceptedCount'}     | ${1}      | ${'1'}
    ${'rejectedCount'}     | ${567}    | ${'567'}
    ${'suggestionSizeSum'} | ${500000} | ${'500,000'}
    ${'acceptanceRate'}    | ${0.75}   | ${'75%'}
    ${'successRate'}       | ${0.95}   | ${'95%'}
    ${'failureRate'}       | ${0.04}   | ${'4%'}
    ${'canceledRate'}      | ${0.01}   | ${'1%'}
    ${'skippedRate'}       | ${0.001}  | ${'0.1%'}
    ${'duration'}          | ${3600}   | ${'1h'}
    ${'queuedDuration'}    | ${90}     | ${'1m 30s'}
    ${'durationQuantile'}  | ${3661}   | ${'1h 1m 1s'}
  `(
    'returns a formatter for $fieldKey that maps $input to $expected',
    ({ fieldKey, input, expected }) => {
      expect(formatterFor(fieldKey)(input)).toBe(expected);
    },
  );

  it('returns an identity-string formatter for unknown field keys', () => {
    const formatter = formatterFor('unknownField');
    expect(formatter(123)).toBe('123');
    expect(formatter('hello')).toBe('hello');
  });

  it('renders nullish values as an empty string for unknown field keys', () => {
    const formatter = formatterFor('unknownField');
    expect(formatter(null)).toBe('');
    expect(formatter(undefined)).toBe('');
  });
});

describe('axisFormatterFor', () => {
  it.each`
    fieldKey               | input      | expected
    ${'totalCount'}        | ${2500000} | ${'2.5M'}
    ${'usersCount'}        | ${1500}    | ${'1.5K'}
    ${'shownCount'}        | ${1234}    | ${'1.2K'}
    ${'acceptedCount'}     | ${1234567} | ${'1.2M'}
    ${'rejectedCount'}     | ${999}     | ${'999'}
    ${'suggestionSizeSum'} | ${500000}  | ${'500K'}
  `('uses compact notation for count $fieldKey', ({ fieldKey, input, expected }) => {
    expect(axisFormatterFor(fieldKey)(input)).toBe(expected);
  });

  it.each`
    fieldKey              | input    | expected
    ${'successRate'}      | ${0.819} | ${'81.9%'}
    ${'durationQuantile'} | ${10000} | ${'2.8h'}
    ${'duration'}         | ${3661}  | ${'1h'}
    ${'queuedDuration'}   | ${90}    | ${'1.5min'}
  `('uses the unit-specific axis formatter for $fieldKey', ({ fieldKey, input, expected }) => {
    expect(axisFormatterFor(fieldKey)(input)).toBe(expected);
  });

  it('falls through to identity for unknown field keys', () => {
    expect(axisFormatterFor('unknownField')(123)).toBe('123');
  });
});

describe('unitFor', () => {
  it.each`
    fieldKey               | expected
    ${'totalCount'}        | ${'count'}
    ${'usersCount'}        | ${'count'}
    ${'suggestionSizeSum'} | ${'count'}
    ${'acceptanceRate'}    | ${'rate'}
    ${'failureRate'}       | ${'rate'}
    ${'duration'}          | ${'duration'}
    ${'durationQuantile'}  | ${'duration'}
  `('maps $fieldKey to unit $expected', ({ fieldKey, expected }) => {
    expect(unitFor(fieldKey)).toBe(expected);
  });

  it('returns null for unknown field keys', () => {
    expect(unitFor('unknownField')).toBeNull();
  });
});

describe('labelForUnit', () => {
  it.each`
    unit          | expected
    ${'count'}    | ${'Count'}
    ${'rate'}     | ${'Percentage'}
    ${'duration'} | ${'Duration'}
  `('maps $unit to $expected', ({ unit, expected }) => {
    expect(labelForUnit(unit)).toBe(expected);
  });

  it('returns an empty string for unknown units', () => {
    expect(labelForUnit('unknown')).toBe('');
  });

  it('returns an empty string for null', () => {
    expect(labelForUnit(null)).toBe('');
  });
});

describe('buildFormatterByLabel', () => {
  const TOTAL_COUNT = { key: 'totalCount', label: 'Total count' };
  const ACCEPTANCE_RATE = { key: 'acceptanceRate', label: 'Acceptance rate' };

  it('returns a map of label to cell formatter', () => {
    const map = buildFormatterByLabel([TOTAL_COUNT, ACCEPTANCE_RATE]);

    expect(map['Total count'](1234)).toBe('1,234');
    expect(map['Acceptance rate'](0.75)).toBe('75%');
  });

  it('returns an empty object for an empty metrics list', () => {
    expect(buildFormatterByLabel([])).toEqual({});
  });
});

describe('formatValueForLabel', () => {
  const formatterByLabel = buildFormatterByLabel([
    { key: 'totalCount', label: 'Total count' },
    { key: 'acceptanceRate', label: 'Acceptance rate' },
  ]);

  it('applies the correct formatter for a known label', () => {
    expect(formatValueForLabel(formatterByLabel, 'Total count', 1234)).toBe('1,234');
    expect(formatValueForLabel(formatterByLabel, 'Acceptance rate', 0.75)).toBe('75%');
  });

  it('falls back to identity formatting for an unknown label', () => {
    expect(formatValueForLabel(formatterByLabel, 'Unknown', 42)).toBe('42');
  });

  it('renders null as an empty string for an unknown label', () => {
    expect(formatValueForLabel(formatterByLabel, 'Unknown', null)).toBe('');
  });
});

describe('buildSharedAxisFormatter', () => {
  it('returns a formatter when all metrics share the same unit', () => {
    const metrics = [
      { key: 'shownCount', label: 'Shown' },
      { key: 'acceptedCount', label: 'Accepted' },
    ];
    const formatter = buildSharedAxisFormatter(metrics);

    expect(formatter).not.toBeNull();
    expect(formatter(2500000)).toBe('2.5M');
  });

  it('returns null when metrics have mixed units', () => {
    const metrics = [
      { key: 'totalCount', label: 'Total count' },
      { key: 'acceptanceRate', label: 'Acceptance rate' },
    ];

    expect(buildSharedAxisFormatter(metrics)).toBeNull();
  });

  it('returns null when any metric has an unknown unit', () => {
    const metrics = [
      { key: 'totalCount', label: 'Total count' },
      { key: 'unknownField', label: 'Unknown' },
    ];

    expect(buildSharedAxisFormatter(metrics)).toBeNull();
  });

  it('returns null for an empty metrics list', () => {
    expect(buildSharedAxisFormatter([])).toBeNull();
  });
});

describe('yAxisTitleFor', () => {
  it('returns the metric label for a single metric', () => {
    const metrics = [{ key: 'totalCount', label: 'Total count' }];

    expect(yAxisTitleFor(metrics)).toBe('Total count');
  });

  it('returns the unit label when multiple metrics share the same unit', () => {
    const metrics = [
      { key: 'shownCount', label: 'Shown' },
      { key: 'acceptedCount', label: 'Accepted' },
      { key: 'rejectedCount', label: 'Rejected' },
    ];

    expect(yAxisTitleFor(metrics)).toBe('Count');
  });

  it('returns the unit label for rate metrics', () => {
    const metrics = [
      { key: 'successRate', label: 'Success rate' },
      { key: 'failureRate', label: 'Failure rate' },
    ];

    expect(yAxisTitleFor(metrics)).toBe('Percentage');
  });

  it('returns an empty string when metrics have mixed units', () => {
    const metrics = [
      { key: 'totalCount', label: 'Total count' },
      { key: 'acceptanceRate', label: 'Acceptance rate' },
    ];

    expect(yAxisTitleFor(metrics)).toBe('');
  });

  it('returns an empty string when any metric has an unknown unit', () => {
    const metrics = [
      { key: 'totalCount', label: 'Total count' },
      { key: 'unknownField', label: 'Unknown' },
    ];

    expect(yAxisTitleFor(metrics)).toBe('');
  });

  it('returns the metric label even when the unit is unknown', () => {
    const metrics = [{ key: 'unknownField', label: 'Unknown thing' }];

    expect(yAxisTitleFor(metrics)).toBe('Unknown thing');
  });

  it('returns an empty string for an empty metrics list', () => {
    expect(yAxisTitleFor([])).toBe('');
  });
});
