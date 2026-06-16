import fetch from '~/analytics/analytics_dashboards/data_sources/merge_requests';
import { defaultClient } from '~/analytics/analytics_dashboards/graphql/client';
import {
  DATE_RANGE_OPTION_LAST_60_DAYS,
  DATE_RANGE_OPTION_LAST_365_DAYS,
} from '~/explore/analytics_dashboards/components/constants';
import {
  mockThroughputFiltersQueryObject,
  mockThroughputSearchFilters,
  throughputTableData,
} from 'jest/analytics/merge_request_analytics/mock_data';

const mockPageInfo = {
  hasNextPage: false,
  hasPreviousPage: false,
  startCursor: 'this-is-a-start-cursor',
  endCursor: 'this-is-an-end-cursor',
  __typename: 'PageInfo',
};

const mockMergeRequestsResponseData = {
  mergeRequests: {
    nodes: throughputTableData,
    pageInfo: mockPageInfo,
  },
};

const defaultFilters = {
  labels: null,
  notLabels: null,
  sourceBranches: null,
  targetBranches: null,
};

const mockResolvedQuery = ({ mergeRequests = [] } = {}) =>
  jest.spyOn(defaultClient, 'query').mockResolvedValue({ data: { project: { mergeRequests } } });

const expectQueryWithVariables = (variables) =>
  expect(defaultClient.query).toHaveBeenCalledWith(
    expect.objectContaining({
      variables: expect.objectContaining({
        ...defaultFilters,
        ...variables,
      }),
    }),
  );

describe('Merge requests data source', () => {
  let mockSetVisualizationOverrides;
  let res;

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
      setVisualizationOverrides: mockSetVisualizationOverrides,
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
      fullPath: namespace,
      startDate: new Date('2019-07-07'),
      endDate: new Date('2020-07-07'),
      labels: ['a', 'b'],
      milestoneTitle: '101',
      authorUsername: 'Dr. Gero',
    });

    expect(defaultClient.query).toHaveBeenCalledTimes(1);
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
      fullPath: namespace,
      startDate: new Date('2020-05-07'),
      endDate: new Date('2020-07-07'),
      ...mockThroughputFiltersQueryObject,
    });

    expect(defaultClient.query).toHaveBeenCalledTimes(1);
  });

  it('can transform pagination into correct query parameters', async () => {
    mockResolvedQuery();

    res = await fetch({
      namespace,
      query: {
        ...defaultQueryParams,
        pagination: { first: 10, endCursor: 'end' },
      },
    });

    expectQueryWithVariables({
      fullPath: namespace,
      startDate: new Date('2020-05-07'),
      endDate: new Date('2020-07-07'),
      firstPageSize: 10,
      nextPageCursor: 'end',
    });

    expect(defaultClient.query).toHaveBeenCalledTimes(1);
  });

  it('can override default pagination', async () => {
    mockResolvedQuery();

    res = await fetch({
      namespace,
      query: {
        ...defaultQueryParams,
        pagination: { last: 20, startCursor: 'start' },
      },
    });

    expectQueryWithVariables({
      fullPath: namespace,
      startDate: new Date('2020-05-07'),
      endDate: new Date('2020-07-07'),
      lastPageSize: 20,
      prevPageCursor: 'start',
    });

    expect(defaultClient.query).toHaveBeenCalledTimes(1);
  });

  it('sets the visualization subtitle', async () => {
    mockResolvedQuery();

    res = await fetch({
      setVisualizationOverrides: mockSetVisualizationOverrides,
      namespace,
      query: {
        ...defaultQueryParams,
        pagination: { first: 10, endCursor: 'end' },
      },
    });

    expect(mockSetVisualizationOverrides).toHaveBeenCalledWith({
      visualizationOptionOverrides: { subtitle: 'Last 60 days' },
    });
  });

  describe('with data available', () => {
    beforeEach(async () => {
      mockResolvedQuery(mockMergeRequestsResponseData);

      res = await fetch({
        setVisualizationOverrides: mockSetVisualizationOverrides,
        namespace,
        query: defaultQueryParams,
      });
    });

    it('sets the correct query parameters', () => {
      expectQueryWithVariables({
        fullPath: namespace,
        startDate: new Date('2020-05-07'),
        endDate: new Date('2020-07-07'),
      });

      expect(defaultClient.query).toHaveBeenCalledTimes(1);
    });

    it('returns data and pagination information', () => {
      expect(res).toMatchSnapshot();
    });
  });

  describe('with no data available', () => {
    beforeEach(async () => {
      mockResolvedQuery();

      res = await fetch({
        setVisualizationOverrides: mockSetVisualizationOverrides,
        namespace,
        query: defaultQueryParams,
      });
    });

    it('returns null', () => {
      expect(res).toBeNull();
    });
  });
});
