import { GlAlert } from '@gitlab/ui';
import { GlLineChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import UsageTrendsCountChart from '~/analytics/usage_trends/components/usage_trends_count_chart.vue';
import statsQuery from '~/analytics/usage_trends/graphql/queries/usage_count.query.graphql';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import { mockQueryResponse, mockApolloResponse } from '../apollo_mock_data';
import { mockCountsData1 } from '../mock_data';

Vue.use(VueApollo);

const loadChartErrorMessage = 'My load error message';
const noDataMessage = 'My no data message';

const queryResponseDataKey = 'usageTrendsMeasurements';
const identifier = 'MOCK_QUERY';
const mockQueryConfig = {
  identifier,
  title: 'Mock Query',
  query: statsQuery,
  loadError: 'Failed to load mock query data',
};

const mockChartConfig = {
  loadChartErrorMessage,
  noDataMessage,
  chartTitle: 'Foo',
  yAxisTitle: 'Bar',
  xAxisTitle: 'Baz',
  queries: [mockQueryConfig],
};

describe('UsageTrendsCountChart', () => {
  let wrapper;
  let queryHandler;

  const createComponent = ({ responseHandler }) => {
    return shallowMount(UsageTrendsCountChart, {
      apolloProvider: createMockApollo([[statsQuery, responseHandler]]),
      propsData: { ...mockChartConfig },
    });
  };

  const findLoader = () => wrapper.findComponent(ChartSkeletonLoader);
  const findChart = () => wrapper.findComponent(GlLineChart);
  const findAlert = () => wrapper.findComponent(GlAlert);

  describe('while loading', () => {
    beforeEach(() => {
      queryHandler = mockQueryResponse({ key: queryResponseDataKey, loading: true });
      wrapper = createComponent({ responseHandler: queryHandler });
    });

    it('requests data', () => {
      expect(queryHandler).toHaveBeenCalledTimes(1);
    });

    it('displays the skeleton loader', () => {
      expect(findLoader().exists()).toBe(true);
    });

    it('hides the chart', () => {
      expect(findChart().exists()).toBe(false);
    });

    it('does not show an error', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('without data', () => {
    beforeEach(async () => {
      queryHandler = mockQueryResponse({ key: queryResponseDataKey, data: [] });
      wrapper = createComponent({ responseHandler: queryHandler });
      await waitForPromises();
    });

    it('renders an no data message', () => {
      expect(findAlert().text()).toBe(noDataMessage);
    });

    it('hides the skeleton loader', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('renders the chart', () => {
      expect(findChart().exists()).toBe(false);
    });
  });

  describe('with data', () => {
    beforeEach(async () => {
      queryHandler = mockQueryResponse({ key: queryResponseDataKey, data: mockCountsData1 });
      wrapper = createComponent({ responseHandler: queryHandler });
      await waitForPromises();
    });

    it('requests data', () => {
      expect(queryHandler).toHaveBeenCalledTimes(1);
    });

    it('hides the skeleton loader', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('renders the chart', () => {
      expect(findChart().exists()).toBe(true);
    });

    it('passes the data to the line chart', () => {
      expect(findChart().props('data')).toMatchSnapshot();
    });

    it('does not show an error', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('when fetching more data', () => {
    const recordedAt = '2020-08-01';
    describe('when the fetchMore query returns data', () => {
      beforeEach(async () => {
        const newData = [{ __typename: 'UsageTrendsMeasurement', recordedAt, count: 5 }];
        queryHandler = mockQueryResponse({
          key: queryResponseDataKey,
          data: mockCountsData1,
          additionalData: newData,
        });

        wrapper = createComponent({ responseHandler: queryHandler });
        await waitForPromises();
      });

      it('requests data twice', () => {
        expect(queryHandler).toHaveBeenCalledTimes(2);
      });

      it('passes the data to the line chart', () => {
        expect(findChart().props('data')).toMatchSnapshot();
      });
    });

    describe('when the fetchMore query throws an error', () => {
      beforeEach(async () => {
        queryHandler = jest.fn().mockResolvedValueOnce(
          mockApolloResponse({
            key: queryResponseDataKey,
            data: mockCountsData1,
            hasNextPage: true,
          }),
        );

        wrapper = createComponent({ responseHandler: queryHandler });
        jest
          .spyOn(wrapper.vm.$apollo.queries[identifier], 'fetchMore')
          .mockImplementation(jest.fn().mockRejectedValue());

        await nextTick();
      });

      it('calls fetchMore', () => {
        expect(wrapper.vm.$apollo.queries[identifier].fetchMore).toHaveBeenCalledTimes(1);
      });

      it('show an error message', () => {
        expect(findAlert().text()).toBe(loadChartErrorMessage);
      });
    });
  });
});
