import { GlAlert } from '@gitlab/ui';
import { GlLineChart } from '@gitlab/ui/dist/charts';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import UsageTrendsCountChart from '~/analytics/usage_trends/components/usage_trends_count_chart.vue';
import statsQuery from '~/analytics/usage_trends/graphql/queries/usage_count.query.graphql';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import { mockQueryResponse, mockApolloResponse } from '../apollo_mock_data';
import { mockCountsData1, mockCountsData2 } from '../mock_data';

Vue.use(VueApollo);

const loadChartErrorMessage = 'My load error message';
const noDataMessage = 'My no data message';

const mockError = new Error('Something went wrong');

const queryResponseDataKey = 'usageTrendsMeasurements';
const mockQueries = [
  {
    identifier: 'MOCK_QUERY_1',
    title: 'Mock Query 1',
    query: statsQuery,
    loadError: 'Failed to load mock query 1 data',
  },
  {
    identifier: 'MOCK_QUERY_2',
    title: 'Mock Query 2',
    query: statsQuery,
    loadError: 'Failed to load mock query 2 data',
  },
];

const mockChartConfig = {
  loadChartErrorMessage,
  noDataMessage,
  chartTitle: 'Foo',
  yAxisTitle: 'Bar',
  xAxisTitle: 'Baz',
  queries: mockQueries,
};

describe('UsageTrendsCountChart', () => {
  let wrapper;
  let queryHandler;

  const createWrapper = async ({ responseHandler }) => {
    wrapper = shallowMountExtended(UsageTrendsCountChart, {
      apolloProvider: createMockApollo([[statsQuery, responseHandler]]),
      propsData: { ...mockChartConfig },
    });

    await waitForPromises();
  };

  const findLoader = () => wrapper.findComponent(ChartSkeletonLoader);
  const findChart = () => wrapper.findComponent(GlLineChart);
  const findAllAlerts = () => wrapper.findAllComponents(GlAlert);
  const findErrorsAlert = () => wrapper.findByTestId('usage-trends-count-error-alert');
  const findInfoAlert = () => wrapper.findByTestId('usage-trends-count-info-alert');

  describe('while loading', () => {
    beforeEach(() => {
      queryHandler = mockQueryResponse({ key: queryResponseDataKey, loading: true });
      createWrapper({ responseHandler: queryHandler });
    });

    it('requests data', () => {
      expect(queryHandler).toHaveBeenCalledTimes(2);

      mockQueries.forEach(({ identifier }, idx) => {
        expect(queryHandler).toHaveBeenNthCalledWith(idx + 1, {
          identifier,
          first: 365,
          after: null,
        });
      });
    });

    it('displays the skeleton loader', () => {
      expect(findLoader().exists()).toBe(true);
    });

    it('does not display chart', () => {
      expect(findChart().exists()).toBe(false);
    });

    it('does not display any alerts', () => {
      expect(findAllAlerts()).toHaveLength(0);
    });
  });

  describe('with errors', () => {
    describe('all queries failed', () => {
      beforeEach(() => {
        return createWrapper({ responseHandler: jest.fn().mockRejectedValue(mockError) });
      });

      it('displays alert with generic error message', () => {
        expect(findAllAlerts()).toHaveLength(1);
        expect(findErrorsAlert().text()).toBe(loadChartErrorMessage);
      });

      it('does not display the skeleton loader', () => {
        expect(findLoader().exists()).toBe(false);
      });

      it('does not display the chart', () => {
        expect(findChart().exists()).toBe(false);
      });
    });

    describe('a single query failed', () => {
      beforeEach(() => {
        queryHandler = jest
          .fn()
          .mockResolvedValueOnce(
            mockApolloResponse({
              key: queryResponseDataKey,
              data: mockCountsData1,
            }),
          )
          .mockRejectedValueOnce(mockError);

        return createWrapper({
          responseHandler: queryHandler,
        });
      });

      it('displays alert with correct error message', () => {
        expect(findAllAlerts()).toHaveLength(1);
        expect(findErrorsAlert().text()).toBe('Failed to load mock query 2 data');
      });

      it('does not display the skeleton loader', () => {
        expect(findLoader().exists()).toBe(false);
      });

      it('does not display the chart', () => {
        expect(findChart().exists()).toBe(false);
      });
    });
  });

  describe('without data', () => {
    beforeEach(() => {
      queryHandler = mockQueryResponse({ key: queryResponseDataKey, data: [] });
      return createWrapper({ responseHandler: queryHandler });
    });

    it('displays info alert with no data message', () => {
      expect(findAllAlerts()).toHaveLength(1);
      expect(findInfoAlert().text()).toBe(noDataMessage);
    });

    it('does not display the skeleton loader', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('does not display the chart', () => {
      expect(findChart().exists()).toBe(false);
    });
  });

  describe('with data', () => {
    beforeEach(() => {
      queryHandler = jest
        .fn()
        .mockResolvedValueOnce(
          mockApolloResponse({
            key: queryResponseDataKey,
            data: mockCountsData1,
          }),
        )
        .mockResolvedValueOnce(
          mockApolloResponse({
            key: queryResponseDataKey,
            data: mockCountsData2,
          }),
        );
      return createWrapper({ responseHandler: queryHandler });
    });

    it('displays the chart', () => {
      expect(findChart().exists()).toBe(true);
    });

    it('passes the data to the line chart', () => {
      expect(findChart().props('data')).toMatchSnapshot();
    });

    it('does not display the skeleton loader', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('does not display any alerts', () => {
      expect(findAllAlerts()).toHaveLength(0);
    });
  });

  describe('with multiple pages of data', () => {
    describe('while fetching more data', () => {
      beforeEach(() => {
        queryHandler = jest
          .fn()
          .mockResolvedValueOnce(
            mockApolloResponse({
              key: queryResponseDataKey,
              data: mockCountsData1,
              hasNextPage: false,
            }),
          )
          .mockResolvedValueOnce(
            mockApolloResponse({
              key: queryResponseDataKey,
              data: mockCountsData2,
              hasNextPage: true,
            }),
          )
          .mockReturnValue(new Promise(() => {}));

        return createWrapper({ responseHandler: queryHandler });
      });

      it('displays the skeleton loader', () => {
        expect(findLoader().exists()).toBe(true);
      });

      it('does not display the chart', () => {
        expect(findChart().exists()).toBe(false);
      });

      it('does not display any alerts', () => {
        expect(findAllAlerts()).toHaveLength(0);
      });
    });

    describe('fetched more data', () => {
      beforeEach(() => {
        queryHandler = jest
          .fn()
          .mockResolvedValueOnce(
            mockApolloResponse({
              key: queryResponseDataKey,
              data: mockCountsData1,
              hasNextPage: true,
            }),
          )
          .mockResolvedValueOnce(
            mockApolloResponse({
              key: queryResponseDataKey,
              data: mockCountsData2,
              hasNextPage: true,
            }),
          )
          .mockResolvedValueOnce(
            mockApolloResponse({
              key: queryResponseDataKey,
              data: [{ __typename: 'UsageTrendsMeasurement', recordedAt: '2020-08-01', count: 5 }],
              hasNextPage: false,
            }),
          )
          .mockResolvedValueOnce(
            mockApolloResponse({
              key: queryResponseDataKey,
              data: [{ __typename: 'UsageTrendsMeasurement', recordedAt: '2020-08-05', count: 10 }],
              hasNextPage: false,
            }),
          );

        return createWrapper({ responseHandler: queryHandler });
      });

      it('requests data twice for each query', () => {
        expect(queryHandler).toHaveBeenCalledTimes(4);
      });

      it('passes the data to the line chart', () => {
        expect(findChart().props('data')).toMatchSnapshot();
      });

      it('does not display the skeleton loader', () => {
        expect(findLoader().exists()).toBe(false);
      });

      it('does not display any alerts', () => {
        expect(findAllAlerts()).toHaveLength(0);
      });
    });

    describe('has errors', () => {
      describe('fetching more data for all queries fails', () => {
        beforeEach(() => {
          queryHandler = jest
            .fn()
            .mockResolvedValue(
              mockApolloResponse({
                key: queryResponseDataKey,
                data: mockCountsData1,
                hasNextPage: true,
              }),
            )
            .mockRejectedValue(mockError);

          return createWrapper({ responseHandler: queryHandler });
        });

        it('displays alert with generic error message', () => {
          expect(findAllAlerts()).toHaveLength(1);
          expect(findErrorsAlert().text()).toBe(loadChartErrorMessage);
        });

        it('does not display the skeleton loader', () => {
          expect(findLoader().exists()).toBe(false);
        });

        it('does not display the chart', () => {
          expect(findChart().exists()).toBe(false);
        });
      });

      describe('fetching more data for a single query fails', () => {
        beforeEach(() => {
          queryHandler = jest
            .fn()
            .mockResolvedValue(
              mockApolloResponse({
                key: queryResponseDataKey,
                data: mockCountsData1,
                hasNextPage: true,
              }),
            )
            .mockResolvedValueOnce(
              mockApolloResponse({
                key: queryResponseDataKey,
                data: [
                  { __typename: 'UsageTrendsMeasurement', recordedAt: '2020-08-01', count: 5 },
                ],
                hasNextPage: false,
              }),
            )
            .mockRejectedValueOnce(mockError);

          return createWrapper({ responseHandler: queryHandler });
        });

        it('displays alert with correct error message', () => {
          expect(findAllAlerts()).toHaveLength(1);
          expect(findErrorsAlert().text()).toBe('Failed to load mock query 2 data');
        });

        it('does not display the skeleton loader', () => {
          expect(findLoader().exists()).toBe(false);
        });

        it('does not display the chart', () => {
          expect(findChart().exists()).toBe(false);
        });
      });
    });
  });
});
