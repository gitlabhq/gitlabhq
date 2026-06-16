import { queryThroughputData } from '~/analytics/merge_request_analytics/api';
import { getThroughputChartData } from '~/analytics/merge_request_analytics/graphql/queries/throughput_chart.query.graphql';
import { defaultClient } from '~/analytics/analytics_dashboards/graphql/client';

const mockMergeRequestsCountsResponseData = {
  mergeRequests: {
    count: 10,
    totalTimeToMerge: 1337000, // time in seconds
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
      query: expect.objectContaining(getThroughputChartData),
      variables: expect.objectContaining({
        ...defaultFilters,
        ...variables,
      }),
    }),
  );

describe('Merge request analytics api', () => {
  let res;

  const namespace = 'test-namespace';
  const defaultQueryParams = {
    namespace,
    startDate: new Date('2019-08-07'),
    endDate: new Date('2020-07-07'),
  };

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('can override default query parameters', async () => {
    mockResolvedQuery();
    res = await queryThroughputData({
      ...defaultQueryParams,
      labels: ['a', 'b'],
      milestoneTitle: '101',
      authorUsername: 'Dr. Gero',
    });
    // Check the first and last time periods
    [
      { startDate: '2019-08-07', endDate: '2019-09-01' },
      { startDate: '2020-07-01', endDate: '2020-07-07' },
    ].forEach(({ startDate, endDate }) => {
      expectQueryWithVariables({
        fullPath: namespace,
        startDate,
        endDate,
        labels: ['a', 'b'],
        milestoneTitle: '101',
        authorUsername: 'Dr. Gero',
      });
    });

    expect(defaultClient.query).toHaveBeenCalledTimes(12);
  });

  describe('with data available', () => {
    beforeEach(async () => {
      mockResolvedQuery(mockMergeRequestsCountsResponseData);

      res = await queryThroughputData({
        ...defaultQueryParams,
        startDate: new Date('2020-05-13'),
      });
    });

    it('requests all the time intervals', () => {
      expect(defaultClient.query).toHaveBeenCalledTimes(3);
    });

    it('sets the start and end date for each interval in the date range', () => {
      [
        { startDate: '2020-05-13', endDate: '2020-06-01' },
        { startDate: '2020-06-01', endDate: '2020-07-01' },
        { startDate: '2020-07-01', endDate: '2020-07-07' },
      ].forEach((dateParams) => {
        expectQueryWithVariables({
          ...dateParams,
          fullPath: namespace,
        });
      });
    });

    it('returns each interval in the result', () => {
      expect(Object.keys(res)).toEqual(['May_2020', 'Jun_2020', 'Jul_2020']);
    });
  });

  describe('no data available', () => {
    beforeEach(async () => {
      mockResolvedQuery();

      res = await queryThroughputData({
        namespace,
        query: defaultQueryParams,
      });
    });

    it('returns an empty object', () => {
      expect(res).toEqual({});
    });
  });
});
