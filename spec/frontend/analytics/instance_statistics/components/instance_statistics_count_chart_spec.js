import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlLineChart } from '@gitlab/ui/dist/charts';
import { GlAlert } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import createMockApollo from 'jest/helpers/mock_apollo_helper';
import InstanceStatisticsCountChart from '~/analytics/instance_statistics/components/instance_statistics_count_chart.vue';
import pipelinesStatsQuery from '~/analytics/instance_statistics/graphql/queries/pipeline_stats.query.graphql';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import { mockCountsData1, mockCountsData2 } from '../mock_data';
import { getApolloResponse } from '../apollo_mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

const PIPELINES_KEY_TO_NAME_MAP = {
  total: 'Total',
  succeeded: 'Succeeded',
  failed: 'Failed',
  canceled: 'Canceled',
  skipped: 'Skipped',
};
const loadChartErrorMessage = 'My load error message';
const noDataMessage = 'My no data message';

describe('InstanceStatisticsCountChart', () => {
  let wrapper;
  let queryHandler;

  const createApolloProvider = pipelineStatsHandler => {
    return createMockApollo([[pipelinesStatsQuery, pipelineStatsHandler]]);
  };

  const createComponent = apolloProvider => {
    return shallowMount(InstanceStatisticsCountChart, {
      localVue,
      apolloProvider,
      propsData: {
        keyToNameMap: PIPELINES_KEY_TO_NAME_MAP,
        prefix: 'pipelines',
        loadChartErrorMessage,
        noDataMessage,
        chartTitle: 'Foo',
        yAxisTitle: 'Bar',
        xAxisTitle: 'Baz',
        query: pipelinesStatsQuery,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findLoader = () => wrapper.find(ChartSkeletonLoader);
  const findChart = () => wrapper.find(GlLineChart);
  const findAlert = () => wrapper.find(GlAlert);

  describe('while loading', () => {
    beforeEach(() => {
      queryHandler = jest.fn().mockReturnValue(new Promise(() => {}));
      const apolloProvider = createApolloProvider(queryHandler);
      wrapper = createComponent(apolloProvider);
    });

    it('requests data', () => {
      expect(queryHandler).toBeCalledTimes(1);
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
    beforeEach(() => {
      const emptyResponse = getApolloResponse();
      queryHandler = jest.fn().mockResolvedValue(emptyResponse);
      const apolloProvider = createApolloProvider(queryHandler);
      wrapper = createComponent(apolloProvider);
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
    beforeEach(() => {
      const response = getApolloResponse({
        pipelinesTotal: mockCountsData1,
        pipelinesSucceeded: mockCountsData2,
        pipelinesFailed: mockCountsData2,
        pipelinesCanceled: mockCountsData1,
        pipelinesSkipped: mockCountsData1,
      });
      queryHandler = jest.fn().mockResolvedValue(response);
      const apolloProvider = createApolloProvider(queryHandler);
      wrapper = createComponent(apolloProvider);
    });

    it('requests data', () => {
      expect(queryHandler).toBeCalledTimes(1);
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
        const newData = { recordedAt, count: 5 };
        const firstResponse = getApolloResponse({
          pipelinesTotal: mockCountsData2,
          pipelinesSucceeded: mockCountsData2,
          pipelinesFailed: mockCountsData1,
          pipelinesCanceled: mockCountsData2,
          pipelinesSkipped: mockCountsData2,
          hasNextPage: true,
        });
        const secondResponse = getApolloResponse({
          pipelinesTotal: [newData],
          pipelinesSucceeded: [newData],
          pipelinesFailed: [newData],
          pipelinesCanceled: [newData],
          pipelinesSkipped: [newData],
          hasNextPage: false,
        });
        queryHandler = jest
          .fn()
          .mockResolvedValueOnce(firstResponse)
          .mockResolvedValueOnce(secondResponse);
        const apolloProvider = createApolloProvider(queryHandler);
        wrapper = createComponent(apolloProvider);

        await wrapper.vm.$nextTick();
      });

      it('requests data twice', () => {
        expect(queryHandler).toBeCalledTimes(2);
      });

      it('passes the data to the line chart', () => {
        expect(findChart().props('data')).toMatchSnapshot();
      });
    });

    describe('when the fetchMore query throws an error', () => {
      beforeEach(async () => {
        const response = getApolloResponse({
          pipelinesTotal: mockCountsData2,
          pipelinesSucceeded: mockCountsData2,
          pipelinesFailed: mockCountsData1,
          pipelinesCanceled: mockCountsData2,
          pipelinesSkipped: mockCountsData2,
          hasNextPage: true,
        });
        queryHandler = jest.fn().mockResolvedValue(response);
        const apolloProvider = createApolloProvider(queryHandler);
        wrapper = createComponent(apolloProvider);
        jest
          .spyOn(wrapper.vm.$apollo.queries.pipelineStats, 'fetchMore')
          .mockImplementation(jest.fn().mockRejectedValue());
        await wrapper.vm.$nextTick();
      });

      it('calls fetchMore', () => {
        expect(wrapper.vm.$apollo.queries.pipelineStats.fetchMore).toHaveBeenCalledTimes(1);
      });

      it('show an error message', () => {
        expect(findAlert().text()).toBe(loadChartErrorMessage);
      });
    });
  });
});
