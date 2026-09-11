import {
  TREND_CHANGE_KEY,
  TREND_PREVIOUS_KEY,
  hasTemporalDimension,
  hasUniqueRowKeys,
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

describe('hasUniqueRowKeys', () => {
  it('is true when a single dimension distinguishes the rows', () => {
    const nodes = [{ language: 'ruby' }, { language: 'go' }];

    expect(hasUniqueRowKeys(nodes, [mockLanguageDimension])).toBe(true);
  });

  it('is true when the rows differ only in their second dimension', () => {
    const nodes = [
      { project: mockProject('a/b'), language: 'ruby' },
      { project: mockProject('a/b'), language: 'go' },
    ];

    expect(hasUniqueRowKeys(nodes, [mockProjectDimension, mockLanguageDimension])).toBe(true);
  });

  it('is true for a single row with no dimensions', () => {
    expect(hasUniqueRowKeys([{ totalCount: 1 }], [])).toBe(true);
  });

  describe('when an object dimension value has no id', () => {
    it('is true, because unidentifiable rows never pair and cannot be mispaired', () => {
      const nodes = [
        { project: { __typename: 'Namespace', fullName: 'Group A', webUrl: '/groups/group-a' } },
        { project: { __typename: 'Namespace', fullName: 'Group B', webUrl: '/groups/group-b' } },
      ];

      expect(hasUniqueRowKeys(nodes, [mockProjectDimension])).toBe(true);
    });
  });

  describe('when two rows share a label but not an identity', () => {
    it('is true, because they are told apart by id', () => {
      const nodes = [
        { user: mockUser('gid://gitlab/User/1', 'Alex Smith') },
        { user: mockUser('gid://gitlab/User/2', 'Alex Smith') },
      ];

      expect(hasUniqueRowKeys(nodes, [{ key: 'user', type: 'dimension' }])).toBe(true);
    });
  });

  describe('when two rows share an identity', () => {
    it('is false', () => {
      const nodes = [
        { user: mockUser('gid://gitlab/User/1', 'Alex Smith') },
        { user: mockUser('gid://gitlab/User/1', 'Alex Smith') },
      ];

      expect(hasUniqueRowKeys(nodes, [{ key: 'user', type: 'dimension' }])).toBe(false);
    });
  });

  describe('when two rows share a dimension value', () => {
    it('is false', () => {
      const nodes = [{ language: 'ruby' }, { language: 'ruby' }];

      expect(hasUniqueRowKeys(nodes, [mockLanguageDimension])).toBe(false);
    });
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

    it('pairs it with the previous period row that is also null', () => {
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

    it('stays distinct from a row whose value is the literal Unknown', () => {
      const literalUnknownNodes = [
        { project: null, language: 'ruby' },
        { project: 'Unknown', language: 'ruby' },
      ];

      expect(hasUniqueRowKeys(literalUnknownNodes, dimensions)).toBe(true);
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
    it('leaves the row unpaired rather than matching it on its label', () => {
      const rows = withTrendValues(
        [
          {
            project: { __typename: 'Namespace', fullName: 'Group A', webUrl: '/groups/group-a' },
            totalCount: 10,
          },
        ],
        {
          comparisonNodes: [
            {
              project: { __typename: 'Namespace', fullName: 'Group B', webUrl: '/groups/group-b' },
              totalCount: 5,
            },
          ],
          dimensions: [mockProjectDimension],
          metric: mockTotalCountMetric,
        },
      );

      expect(rows[0][TREND_PREVIOUS_KEY]).toBe(null);
      expect(rows[0][TREND_CHANGE_KEY]).toBe(null);
    });

    it('does not pair it with an identifiable row either', () => {
      const rows = withTrendValues(
        [
          {
            project: { __typename: 'Namespace', fullName: 'Group A', webUrl: '/groups/group-a' },
            totalCount: 10,
          },
        ],
        {
          comparisonNodes: [{ project: mockProject('acme / cli'), totalCount: 5 }],
          dimensions: [mockProjectDimension],
          metric: mockTotalCountMetric,
        },
      );

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
