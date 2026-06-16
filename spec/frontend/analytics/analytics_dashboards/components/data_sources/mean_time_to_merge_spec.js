import fetch from '~/analytics/analytics_dashboards/data_sources/mean_time_to_merge';
import * as api from '~/analytics/merge_request_analytics/api';
import {
  DATE_RANGE_OPTION_LAST_60_DAYS,
  DATE_RANGE_OPTION_LAST_365_DAYS,
} from '~/explore/analytics_dashboards/components/constants';
import {
  mockQueryThroughputDataResponse,
  mockThroughputFiltersQueryObject,
  mockThroughputSearchFilters,
} from 'jest/analytics/merge_request_analytics/mock_data';

const mockResolvedQuery = (resp = {}) =>
  jest.spyOn(api, 'queryThroughputData').mockResolvedValue(resp);

const expectQueryWithVariables = (variables) =>
  expect(api.queryThroughputData).toHaveBeenCalledWith(expect.objectContaining(variables));

describe('Mean time to merge data source', () => {
  let res;
  let mockSetVisualizationOverrides;

  const namespace = 'test-namespace';
  const defaultQueryParams = {
    dateRange: DATE_RANGE_OPTION_LAST_60_DAYS,
  };

  afterEach(() => {
    jest.clearAllMocks();
  });

  beforeEach(() => {
    mockSetVisualizationOverrides = jest.fn();
  });

  it('can override default query parameters', async () => {
    mockResolvedQuery();

    res = await fetch({
      namespace,
      query: {
        ...defaultQueryParams,
        dateRange: DATE_RANGE_OPTION_LAST_365_DAYS,
        labels: ['a', 'b'],
        milestoneTitle: '101',
        authorUsername: 'Dr. Gero',
      },
    });

    expectQueryWithVariables({
      namespace,
      startDate: new Date('2019-07-07'),
      endDate: new Date('2020-07-07'),
      labels: ['a', 'b'],
      milestoneTitle: '101',
      authorUsername: 'Dr. Gero',
    });
  });

  it('can transform search filters into correct query parameters', async () => {
    mockResolvedQuery();

    res = await fetch({
      setVisualizationOverrides: mockSetVisualizationOverrides,
      namespace,
      query: defaultQueryParams,
      filters: {
        searchFilters: mockThroughputSearchFilters,
      },
    });

    expectQueryWithVariables({
      namespace,
      startDate: new Date('2020-05-07'),
      endDate: new Date('2020-07-07'),
      ...mockThroughputFiltersQueryObject,
    });
  });

  it('sets the visualization subtitle', async () => {
    mockResolvedQuery();

    res = await fetch({
      setVisualizationOverrides: mockSetVisualizationOverrides,
      namespace,
      query: defaultQueryParams,
      filters: {
        searchFilters: mockThroughputSearchFilters,
      },
    });

    expect(mockSetVisualizationOverrides).toHaveBeenCalledWith({
      visualizationOptionOverrides: { subtitle: 'Last 60 days' },
    });
  });

  describe('with data available', () => {
    beforeEach(async () => {
      mockResolvedQuery(mockQueryThroughputDataResponse);

      res = await fetch({ namespace, query: defaultQueryParams });
    });

    it('returns a single value representing the mean time to merge', () => {
      expect(res).toEqual(2);
    });
  });

  describe('no data available', () => {
    beforeEach(async () => {
      mockResolvedQuery();

      res = await fetch({ namespace });
    });

    it('returns a "-"', () => {
      expect(res).toEqual('-');
    });
  });
});
