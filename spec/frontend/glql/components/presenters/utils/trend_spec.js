import {
  TREND_CHANGE_KEY,
  TREND_PREVIOUS_KEY,
  formatChange,
  formatSignedChange,
  hasTemporalDimension,
  trendChangeFor,
  trendPresentationFor,
  withTrendValues,
} from '~/glql/components/presenters/utils/trend';

const metric = (key, extra = {}) => ({ key, name: key, label: key, type: 'metric', ...extra });

const mockLanguageDimension = { key: 'language', label: 'Language', type: 'dimension' };
const mockProjectDimension = { key: 'project', label: 'Project', type: 'dimension' };
const mockTotalCountMetric = { key: 'totalCount', label: 'Total count', type: 'metric' };

const mockProject = (name, id = `gid://gitlab/Project/${name}`) => ({
  __typename: 'Project',
  id,
  nameWithNamespace: name,
});
const mockUser = (id, name) => ({ __typename: 'UserCore', id, name });

describe('trendChangeFor', () => {
  it.each`
    value    | previousValue | expected
    ${120}   | ${100}        | ${0.2}
    ${80}    | ${100}        | ${-0.2}
    ${100}   | ${100}        | ${0}
    ${0}     | ${100}        | ${-1}
    ${0}     | ${0}          | ${0}
    ${1234}  | ${1000}       | ${0.234}
    ${10006} | ${10000}      | ${0.001}
  `('is $expected for $value against $previousValue', ({ value, previousValue, expected }) => {
    expect(trendChangeFor(value, previousValue)).toBe(expected);
  });

  it.each`
    value        | previousValue
    ${120}       | ${0}
    ${null}      | ${100}
    ${100}       | ${null}
    ${undefined} | ${100}
    ${100}       | ${undefined}
  `('has no change to show for $value against $previousValue', ({ value, previousValue }) => {
    expect(trendChangeFor(value, previousValue)).toBe(null);
  });

  // The badge renders one decimal place, so a change that rounds away has to be flat here
  // too, or the arrow and the ordering would disagree. Signed zero is what `Math.sign`
  // yields for a negative rounding to nothing; it compares equal to 0, so it sorts as flat.
  it.each`
    value    | previousValue | expected
    ${10004} | ${10000}      | ${0}
    ${9996}  | ${10000}      | ${-0}
  `(
    'rounds $value against $previousValue away to $expected',
    ({ value, previousValue, expected }) => {
      expect(trendChangeFor(value, previousValue)).toBe(expected);
    },
  );
});

describe('formatChange', () => {
  it.each`
    change   | expected
    ${0.2}   | ${'20%'}
    ${-0.2}  | ${'20%'}
    ${0}     | ${'0%'}
    ${0.234} | ${'23.4%'}
    ${0.001} | ${'0.1%'}
    ${-1}    | ${'100%'}
  `('formats $change as $expected', ({ change, expected }) => {
    expect(formatChange(change)).toBe(expected);
  });
});

describe('formatSignedChange', () => {
  it.each`
    change   | expected
    ${0.07}  | ${'+7%'}
    ${-0.04} | ${'-4%'}
    ${0}     | ${'0%'}
    ${-0}    | ${'0%'}
    ${0.234} | ${'+23.4%'}
    ${-1}    | ${'-100%'}
  `('formats $change as $expected', ({ change, expected }) => {
    expect(formatSignedChange(change)).toBe(expected);
  });
});

describe('trendPresentationFor', () => {
  it.each`
    source               | fieldKey              | value    | previousValue | expected
    ${'CodeSuggestions'} | ${'totalCount'}       | ${120}   | ${100}        | ${{ metaText: '20% vs prior', metaIcon: 'arrow-up', metaTooltip: 'Up 20% from 100 in the previous period', variant: 'success' }}
    ${'CodeSuggestions'} | ${'totalCount'}       | ${80}    | ${100}        | ${{ metaText: '20% vs prior', metaIcon: 'arrow-down', metaTooltip: 'Down 20% from 100 in the previous period', variant: 'danger' }}
    ${'CodeSuggestions'} | ${'totalCount'}       | ${100}   | ${100}        | ${{ metaText: '0% vs prior', metaIcon: null, metaTooltip: 'No change from 100 in the previous period', variant: 'neutral' }}
    ${'CodeSuggestions'} | ${'totalCount'}       | ${0}     | ${100}        | ${{ metaText: '100% vs prior', metaIcon: 'arrow-down', metaTooltip: 'Down 100% from 100 in the previous period', variant: 'danger' }}
    ${'CodeSuggestions'} | ${'totalCount'}       | ${0}     | ${0}          | ${{ metaText: '0% vs prior', metaIcon: null, metaTooltip: 'No change from 0 in the previous period', variant: 'neutral' }}
    ${'CodeSuggestions'} | ${'totalCount'}       | ${120}   | ${0}          | ${{ metaText: 'New', metaIcon: 'arrow-up', metaTooltip: 'Up from 0 in the previous period', variant: 'neutral' }}
    ${'CodeSuggestions'} | ${'acceptanceRate'}   | ${0.6}   | ${0}          | ${{ metaText: 'New', metaIcon: 'arrow-up', metaTooltip: 'Up from 0% in the previous period', variant: 'neutral' }}
    ${'CodeSuggestions'} | ${'rejectedCount'}    | ${120}   | ${0}          | ${{ metaText: 'New', metaIcon: 'arrow-up', metaTooltip: 'Up from 0 in the previous period', variant: 'neutral' }}
    ${'CodeSuggestions'} | ${'totalCount'}       | ${1234}  | ${1000}       | ${{ metaText: '23.4% vs prior', metaIcon: 'arrow-up', metaTooltip: 'Up 23.4% from 1,000 in the previous period', variant: 'success' }}
    ${'CodeSuggestions'} | ${'totalCount'}       | ${10004} | ${10000}      | ${{ metaText: '0% vs prior', metaIcon: null, metaTooltip: 'No change from 10,000 in the previous period', variant: 'neutral' }}
    ${'CodeSuggestions'} | ${'totalCount'}       | ${9996}  | ${10000}      | ${{ metaText: '0% vs prior', metaIcon: null, metaTooltip: 'No change from 10,000 in the previous period', variant: 'neutral' }}
    ${'CodeSuggestions'} | ${'totalCount'}       | ${10006} | ${10000}      | ${{ metaText: '0.1% vs prior', metaIcon: 'arrow-up', metaTooltip: 'Up 0.1% from 10,000 in the previous period', variant: 'success' }}
    ${'CodeSuggestions'} | ${'acceptanceRate'}   | ${0.6}   | ${0.5}        | ${{ metaText: '20% vs prior', metaIcon: 'arrow-up', metaTooltip: 'Up 20% from 50% in the previous period', variant: 'success' }}
    ${'CodeSuggestions'} | ${'rejectedCount'}    | ${120}   | ${100}        | ${{ metaText: '20% vs prior', metaIcon: 'arrow-up', metaTooltip: 'Up 20% from 100 in the previous period', variant: 'danger' }}
    ${'Pipelines'}       | ${'durationQuantile'} | ${90}    | ${120}        | ${{ metaText: '25% vs prior', metaIcon: 'arrow-down', metaTooltip: 'Down 25% from 2m in the previous period', variant: 'success' }}
    ${'CodeSuggestions'} | ${'somethingCustom'}  | ${120}   | ${100}        | ${{ metaText: '20% vs prior', metaIcon: 'arrow-up', metaTooltip: 'Up 20% from 100 in the previous period', variant: 'neutral' }}
  `(
    'describes $fieldKey moving from $previousValue to $value in $source',
    ({ source, fieldKey, value, previousValue, expected }) => {
      expect(trendPresentationFor(source, metric(fieldKey), { value, previousValue })).toEqual(
        expected,
      );
    },
  );

  it('colours through the base field key of an aliased metric', () => {
    const aliased = metric('p50', { field: 'durationQuantile', parameters: { quantile: 0.5 } });

    expect(
      trendPresentationFor('Pipelines', aliased, { value: 90, previousValue: 120 }),
    ).toMatchObject({
      metaTooltip: 'Down 25% from 2m in the previous period',
      variant: 'success',
    });
  });

  it.each`
    value        | previousValue
    ${120}       | ${null}
    ${120}       | ${undefined}
    ${null}      | ${100}
    ${undefined} | ${100}
  `('has no trend for $value against $previousValue', ({ value, previousValue }) => {
    expect(
      trendPresentationFor('CodeSuggestions', metric('totalCount'), { value, previousValue }),
    ).toBeNull();
  });
});

describe('hasTemporalDimension', () => {
  it('is true when a dimension buckets by date', () => {
    const mockWeeklyDimension = {
      key: 'created',
      type: 'dimension',
      parameters: { granularity: 'weekly' },
    };

    expect(hasTemporalDimension([mockLanguageDimension, mockWeeklyDimension])).toBe(true);
  });

  it('is false when no dimension has a granularity', () => {
    expect(hasTemporalDimension([mockLanguageDimension])).toBe(false);
  });

  it('is false when there are no dimensions', () => {
    expect(hasTemporalDimension([])).toBe(false);
  });
});

describe('withTrendValues', () => {
  const nodes = [
    { language: 'ruby', totalCount: 21 },
    { language: 'python', totalCount: 14 },
    { language: 'go', totalCount: 10 },
  ];

  const build = (comparisonNodes, dimensions = [mockLanguageDimension]) =>
    withTrendValues(nodes, { comparisonNodes, dimensions, metric: mockTotalCountMetric });

  it('materialises the change and the previous value against the matching row', () => {
    const [ruby] = build([{ language: 'ruby', totalCount: 20 }]);

    expect(ruby[TREND_PREVIOUS_KEY]).toBe(20);
    expect(ruby[TREND_CHANGE_KEY]).toBe(0.05);
  });

  it('keeps the original row values', () => {
    const [ruby] = build([{ language: 'ruby', totalCount: 20 }]);

    expect(ruby.language).toBe('ruby');
    expect(ruby.totalCount).toBe(21);
  });

  it('records a change of 0 for a row that did not move', () => {
    const [, python] = build([{ language: 'python', totalCount: 14 }]);

    expect(python[TREND_CHANGE_KEY]).toBe(0);
  });

  it('matches rows on all dimensions', () => {
    const twoDimensionNodes = [
      { project: mockProject('a/b'), language: 'ruby', totalCount: 10 },
      { project: mockProject('a/c'), language: 'ruby', totalCount: 10 },
    ];

    const rows = withTrendValues(twoDimensionNodes, {
      comparisonNodes: [{ project: mockProject('a/c'), language: 'ruby', totalCount: 5 }],
      dimensions: [mockProjectDimension, mockLanguageDimension],
      metric: mockTotalCountMetric,
    });

    expect(rows[0][TREND_PREVIOUS_KEY]).toBe(null);
    expect(rows[1][TREND_PREVIOUS_KEY]).toBe(5);
  });

  it('matches the single row of a table with no dimensions', () => {
    const rows = withTrendValues([{ totalCount: 12 }], {
      comparisonNodes: [{ totalCount: 6 }],
      dimensions: [],
      metric: mockTotalCountMetric,
    });

    expect(rows[0][TREND_CHANGE_KEY]).toBe(1);
  });

  it('does not mutate the rows it is given', () => {
    build([{ language: 'ruby', totalCount: 20 }]);

    expect(nodes[0]).toEqual({ language: 'ruby', totalCount: 21 });
  });

  describe('when a row has no counterpart in the previous period', () => {
    it('records the change as unknown rather than as no change', () => {
      const [, , go] = build([{ language: 'ruby', totalCount: 20 }]);

      expect(go[TREND_PREVIOUS_KEY]).toBe(null);
      expect(go[TREND_CHANGE_KEY]).toBe(null);
    });
  });

  describe('when the previous period has no rows at all', () => {
    it('records every change as unknown', () => {
      expect(build([]).map((row) => row[TREND_CHANGE_KEY])).toEqual([null, null, null]);
    });

    it('records every change as unknown when no comparison is given', () => {
      const rows = withTrendValues(nodes, {
        dimensions: [mockLanguageDimension],
        metric: mockTotalCountMetric,
      });

      expect(rows.map((row) => row[TREND_CHANGE_KEY])).toEqual([null, null, null]);
    });
  });

  describe('when the previous value is 0', () => {
    it('records the change as unknown, because a move away from 0 has no percentage', () => {
      const [ruby] = build([{ language: 'ruby', totalCount: 0 }]);

      expect(ruby[TREND_PREVIOUS_KEY]).toBe(0);
      expect(ruby[TREND_CHANGE_KEY]).toBe(null);
    });
  });

  describe('when the previous row has no value for the metric', () => {
    it('records the change as unknown', () => {
      const [ruby] = build([{ language: 'ruby', totalCount: null }]);

      expect(ruby[TREND_CHANGE_KEY]).toBe(null);
    });
  });

  describe('when a dimension value is null', () => {
    const nullDimensionNodes = [
      { project: null, language: 'ruby', totalCount: 10 },
      { project: mockProject('a/b'), language: 'ruby', totalCount: 8 },
    ];
    const dimensions = [mockProjectDimension, mockLanguageDimension];

    it('pairs it with the blank row of the previous period, which is the same bucket', () => {
      const rows = withTrendValues(nullDimensionNodes, {
        comparisonNodes: [{ project: null, language: 'ruby', totalCount: 5 }],
        dimensions,
        metric: mockTotalCountMetric,
      });

      expect(rows[0][TREND_PREVIOUS_KEY]).toBe(5);
      expect(rows[0][TREND_CHANGE_KEY]).toBe(1);
    });

    it('does not pair it with a non-null row', () => {
      const rows = withTrendValues(nullDimensionNodes, {
        comparisonNodes: [{ project: mockProject('a/b'), language: 'ruby', totalCount: 5 }],
        dimensions,
        metric: mockTotalCountMetric,
      });

      expect(rows[0][TREND_PREVIOUS_KEY]).toBe(null);
      expect(rows[1][TREND_PREVIOUS_KEY]).toBe(5);
    });

    it('does not pair it with a row whose value is the literal Unknown', () => {
      const rows = withTrendValues([{ project: null, language: 'ruby', totalCount: 10 }], {
        comparisonNodes: [{ project: 'Unknown', language: 'ruby', totalCount: 5 }],
        dimensions,
        metric: mockTotalCountMetric,
      });

      expect(rows[0][TREND_PREVIOUS_KEY]).toBe(null);
    });
  });

  describe('when several rows of a period share a dimension value', () => {
    const dimensions = [mockProjectDimension];

    it('leaves them unpaired, because neither can be told from the other', () => {
      const rows = withTrendValues(
        [
          { project: null, totalCount: 10 },
          { project: null, totalCount: 8 },
          { project: mockProject('a/b'), totalCount: 6 },
        ],
        {
          comparisonNodes: [
            { project: null, totalCount: 5 },
            { project: mockProject('a/b'), totalCount: 3 },
          ],
          dimensions,
          metric: mockTotalCountMetric,
        },
      );

      expect(rows.map((row) => row[TREND_PREVIOUS_KEY])).toEqual([null, null, 3]);
    });

    it('leaves the matching row of the other period unpaired too', () => {
      const rows = withTrendValues([{ project: null, totalCount: 10 }], {
        comparisonNodes: [
          { project: null, totalCount: 5 },
          { project: null, totalCount: 3 },
        ],
        dimensions,
        metric: mockTotalCountMetric,
      });

      expect(rows[0][TREND_PREVIOUS_KEY]).toBe(null);
    });
  });

  // The three cases raised in review on
  // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/254539
  describe('when rows share a display label but are different records', () => {
    const userDimension = { key: 'user', label: 'User', type: 'dimension' };
    const alexOne = mockUser('gid://gitlab/User/1', 'Alex Smith');
    const alexTwo = mockUser('gid://gitlab/User/2', 'Alex Smith');

    it('pairs each row with its own record, not the same-named one', () => {
      const rows = withTrendValues([{ user: alexOne, totalCount: 10 }], {
        comparisonNodes: [
          { user: alexOne, totalCount: 10 },
          { user: alexTwo, totalCount: 100 },
        ],
        dimensions: [userDimension],
        metric: mockTotalCountMetric,
      });

      expect(rows[0][TREND_PREVIOUS_KEY]).toBe(10);
      expect(rows[0][TREND_CHANGE_KEY]).toBe(0);
    });

    it('does not pair a row with a same-named record that only exists in the previous period', () => {
      const rows = withTrendValues([{ user: alexOne, totalCount: 10 }], {
        comparisonNodes: [{ user: alexTwo, totalCount: 100 }],
        dimensions: [userDimension],
        metric: mockTotalCountMetric,
      });

      expect(rows[0][TREND_PREVIOUS_KEY]).toBe(null);
      expect(rows[0][TREND_CHANGE_KEY]).toBe(null);
    });
  });

  describe('when a dimension value cannot be identified', () => {
    const mockNamespace = (fullName) => ({ __typename: 'Namespace', fullName });

    it('leaves the row unpaired rather than matching it on its label', () => {
      const rows = withTrendValues([{ project: mockNamespace('Group A'), totalCount: 10 }], {
        comparisonNodes: [{ project: mockNamespace('Group B'), totalCount: 5 }],
        dimensions: [mockProjectDimension],
        metric: mockTotalCountMetric,
      });

      expect(rows[0][TREND_PREVIOUS_KEY]).toBe(null);
      expect(rows[0][TREND_CHANGE_KEY]).toBe(null);
    });

    it('leaves it unpaired even against the same unidentified value, unlike a blank', () => {
      const rows = withTrendValues([{ project: mockNamespace('Group A'), totalCount: 10 }], {
        comparisonNodes: [{ project: mockNamespace('Group A'), totalCount: 5 }],
        dimensions: [mockProjectDimension],
        metric: mockTotalCountMetric,
      });

      expect(rows[0][TREND_PREVIOUS_KEY]).toBe(null);
    });

    it('does not pair it with an identifiable row either', () => {
      const rows = withTrendValues([{ project: mockNamespace('Group A'), totalCount: 10 }], {
        comparisonNodes: [{ project: mockProject('acme / cli'), totalCount: 5 }],
        dimensions: [mockProjectDimension],
        metric: mockTotalCountMetric,
      });

      expect(rows[0][TREND_PREVIOUS_KEY]).toBe(null);
    });
  });

  describe('when the previous period has rows the current period does not', () => {
    it('ignores them', () => {
      const rows = build([
        { language: 'ruby', totalCount: 20 },
        { language: 'rust', totalCount: 99 },
      ]);

      expect(rows).toHaveLength(3);
      expect(rows.map((row) => row.language)).toEqual(['ruby', 'python', 'go']);
    });
  });
});
