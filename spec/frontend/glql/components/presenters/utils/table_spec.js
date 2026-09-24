import {
  TREND_CHANGE_KEY,
  TREND_PREVIOUS_KEY,
  hasTemporalDimension,
  withTrendValues,
} from '~/glql/components/presenters/utils/table';

const mockLanguageDimension = { key: 'language', label: 'Language', type: 'dimension' };
const mockProjectDimension = { key: 'project', label: 'Project', type: 'dimension' };
const mockTotalCountMetric = { key: 'totalCount', label: 'Total count', type: 'metric' };

const mockProject = (name, id = `gid://gitlab/Project/${name}`) => ({
  __typename: 'Project',
  id,
  nameWithNamespace: name,
});
const mockUser = (id, name) => ({ __typename: 'UserCore', id, name });

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
