import {
  extractFilterQueryParameters,
  extractPaginationQueryParameters,
  filterBySearchTerm,
  generateValueStreamsDashboardLink,
  getDataZoomOption,
  overviewMetricsRequestParams,
} from '~/analytics/shared/utils';
import { objectToQuery } from '~/lib/utils/url_utility';

describe('filterBySearchTerm', () => {
  const data = [
    { name: 'eins', title: 'one' },
    { name: 'zwei', title: 'two' },
    { name: 'drei', title: 'three' },
  ];
  const searchTerm = 'rei';

  it('filters data by `name` for the provided search term', () => {
    expect(filterBySearchTerm(data, searchTerm)).toEqual([data[2]]);
  });

  it('with no search term returns the data', () => {
    ['', null].forEach((search) => {
      expect(filterBySearchTerm(data, search)).toEqual(data);
    });
  });

  it('with a key, filters by the provided key', () => {
    expect(filterBySearchTerm(data, 'ne', 'title')).toEqual([data[0]]);
  });
});

describe('extractFilterQueryParameters', () => {
  const selectedAuthor = 'Author 1';
  const selectedMilestone = 'Milestone 1.0';
  const selectedSourceBranch = 'main';
  const selectedTargetBranch = 'feature-1';
  const selectedAssigneeList = ['Alice', 'Bob'];
  const selectedLabelList = ['Label 1', 'Label 2'];

  const queryParamsString = objectToQuery({
    source_branch_name: selectedSourceBranch,
    target_branch_name: selectedTargetBranch,
    author_username: selectedAuthor,
    milestone_title: selectedMilestone,
    assignee_username: selectedAssigneeList,
    label_name: selectedLabelList,
  });

  it('extracts the correct filter parameters from a url', () => {
    const result = extractFilterQueryParameters(queryParamsString);
    const operator = '=';
    const expectedFilters = {
      selectedAssigneeList: { operator, value: selectedAssigneeList.join(',') },
      selectedLabelList: { operator, value: selectedLabelList.join(',') },
      selectedAuthor: { operator, value: selectedAuthor },
      selectedMilestone: { operator, value: selectedMilestone },
      selectedSourceBranch: { operator, value: selectedSourceBranch },
      selectedTargetBranch: { operator, value: selectedTargetBranch },
    };
    expect(result).toMatchObject(expectedFilters);
  });

  it('returns null for missing parameters', () => {
    const result = extractFilterQueryParameters('');
    const expectedFilters = {
      selectedAuthor: null,
      selectedMilestone: null,
      selectedSourceBranch: null,
      selectedTargetBranch: null,
    };
    expect(result).toMatchObject(expectedFilters);
  });

  it('only returns the parameters we expect', () => {
    const result = extractFilterQueryParameters('foo="one"&bar="two"');
    const resultKeys = Object.keys(result);
    ['foo', 'bar'].forEach((key) => {
      expect(resultKeys).not.toContain(key);
    });

    [
      'selectedAuthor',
      'selectedMilestone',
      'selectedSourceBranch',
      'selectedTargetBranch',
      'selectedAssigneeList',
      'selectedLabelList',
    ].forEach((key) => {
      expect(resultKeys).toContain(key);
    });
  });

  it('returns an empty array for missing list parameters', () => {
    const result = extractFilterQueryParameters('');
    const expectedFilters = { selectedAssigneeList: [], selectedLabelList: [] };
    expect(result).toMatchObject(expectedFilters);
  });
});

describe('extractPaginationQueryParameters', () => {
  const sort = 'title';
  const direction = 'asc';
  const page = '1';
  const queryParamsString = objectToQuery({ sort, direction, page });

  it('extracts the correct filter parameters from a url', () => {
    const result = extractPaginationQueryParameters(queryParamsString);
    const expectedFilters = { sort, page, direction };
    expect(result).toMatchObject(expectedFilters);
  });

  it('returns null for missing parameters', () => {
    const result = extractPaginationQueryParameters('');
    const expectedFilters = { sort: null, direction: null, page: null };
    expect(result).toMatchObject(expectedFilters);
  });

  it('only returns the parameters we expect', () => {
    const result = extractPaginationQueryParameters('foo="one"&bar="two"&qux="three"');
    const resultKeys = Object.keys(result);
    ['foo', 'bar', 'qux'].forEach((key) => {
      expect(resultKeys).not.toContain(key);
    });

    ['sort', 'page', 'direction'].forEach((key) => {
      expect(resultKeys).toContain(key);
    });
  });
});

describe('getDataZoomOption', () => {
  it('returns an empty object when totalItems <= maxItemsPerPage', () => {
    const totalItems = 10;
    const maxItemsPerPage = 20;

    expect(getDataZoomOption({ totalItems, maxItemsPerPage })).toEqual({});
  });

  describe('when totalItems > maxItemsPerPage', () => {
    const totalItems = 30;
    const maxItemsPerPage = 20;

    it('properly computes the end interval for the default datazoom config', () => {
      const expected = [
        {
          type: 'slider',
          bottom: 10,
          start: 0,
          end: 67,
        },
      ];

      expect(getDataZoomOption({ totalItems, maxItemsPerPage })).toEqual(expected);
    });

    it('properly computes the end interval for a custom datazoom config', () => {
      const dataZoom = [
        { type: 'slider', bottom: 0, start: 0 },
        { type: 'inside', start: 0 },
      ];
      const expected = [
        {
          type: 'slider',
          bottom: 0,
          start: 0,
          end: 67,
        },
        {
          type: 'inside',
          start: 0,
          end: 67,
        },
      ];

      expect(getDataZoomOption({ totalItems, maxItemsPerPage, dataZoom })).toEqual(expected);
    });
  });
});

describe('generateValueStreamsDashboardLink', () => {
  it.each`
    namespacePath                | isProjectNamespace | result
    ${''}                        | ${null}            | ${''}
    ${'fake-group'}              | ${false}           | ${'/groups/fake-group/-/analytics/dashboards/value_streams_dashboard'}
    ${'fake-group/fake-project'} | ${true}            | ${'/fake-group/fake-project/-/analytics/dashboards/value_streams_dashboard'}
  `(
    'generates the dashboard link when namespacePath=namespacePath and isProjectNamespace=$isProjectNamespace',
    ({ namespacePath, isProjectNamespace, result }) => {
      expect(generateValueStreamsDashboardLink(namespacePath, isProjectNamespace)).toBe(result);
    },
  );

  describe('with a relative url root set', () => {
    beforeEach(() => {
      gon.relative_url_root = '/foobar';
    });

    it.each`
      namespacePath                | isProjectNamespace | result
      ${'fake-group'}              | ${false}           | ${'/foobar/groups/fake-group/-/analytics/dashboards/value_streams_dashboard'}
      ${'fake-group/fake-project'} | ${true}            | ${'/foobar/fake-group/fake-project/-/analytics/dashboards/value_streams_dashboard'}
    `('includes a relative path if one is set', ({ namespacePath, isProjectNamespace, result }) => {
      expect(generateValueStreamsDashboardLink(namespacePath, isProjectNamespace)).toBe(result);
    });
  });
});

describe('overviewMetricsRequestParams', () => {
  it('returns empty object when no params provided', () => {
    expect(overviewMetricsRequestParams()).toEqual({});
  });

  it.each`
    requestParam           | value                   | expected
    ${'created_after'}     | ${'2024-01-01'}         | ${'startDate'}
    ${'created_before'}    | ${'2024-12-31'}         | ${'endDate'}
    ${'label_name'}        | ${['bug', 'feature']}   | ${'labelNames'}
    ${'assignee_username'} | ${['user1', 'user2']}   | ${'assigneeUsernames'}
    ${'author_username'}   | ${'Author A'}           | ${'authorUsername'}
    ${'milestone_title'}   | ${'some new milestone'} | ${'milestoneTitle'}
  `('correctly transforms the $requestParam parameter', ({ requestParam, value, expected }) => {
    const result = overviewMetricsRequestParams({ [requestParam]: value });
    expect(result[expected]).toBe(value);
  });
});
