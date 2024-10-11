import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PipelineCharts from '~/projects/pipelines/charts/components/pipeline_charts.vue';
import StatisticsList from '~/projects/pipelines/charts/components/statistics_list.vue';
import getPipelineCountByStatus from '~/projects/pipelines/charts/graphql/queries/get_pipeline_count_by_status.query.graphql';
import getProjectPipelineStatistics from '~/projects/pipelines/charts/graphql/queries/get_project_pipeline_statistics.query.graphql';
import CiCdAnalyticsCharts from '~/vue_shared/components/ci_cd_analytics/ci_cd_analytics_charts.vue';
import { mockPipelineCount, mockPipelineStatistics } from '../mock_data';

const projectPath = 'gitlab-org/gitlab';
Vue.use(VueApollo);

describe('~/projects/pipelines/charts/components/pipeline_charts.vue', () => {
  let wrapper;

  function createMockApolloProvider() {
    const requestHandlers = [
      [getPipelineCountByStatus, jest.fn().mockResolvedValue(mockPipelineCount)],
      [getProjectPipelineStatistics, jest.fn().mockResolvedValue(mockPipelineStatistics)],
    ];

    return createMockApollo(requestHandlers);
  }

  beforeEach(async () => {
    wrapper = shallowMount(PipelineCharts, {
      provide: {
        projectPath,
      },
      apolloProvider: createMockApolloProvider(),
    });

    await waitForPromises();
  });

  describe('overall statistics', () => {
    it('displays the statistics list', () => {
      const list = wrapper.findComponent(StatisticsList);

      expect(list.exists()).toBe(true);
      expect(list.props('counts')).toEqual({
        total: 40,
        successRatio: (23 / 40) * 100,
        failureRatio: (1 / 40) * 100,
      });
    });

    it('displays the commit duration chart', () => {
      const chart = wrapper.findComponent(GlColumnChart);

      expect(chart.exists()).toBe(true);
      expect(chart.props('yAxisTitle')).toBe('Minutes');
      expect(chart.props('xAxisTitle')).toBe('Commit');
      expect(chart.props('bars')).toBe(wrapper.vm.timesChartTransformedData);
      expect(chart.props('option')).toBe(wrapper.vm.chartOptions);
    });
  });

  describe('pipelines charts', () => {
    it('displays the charts components', () => {
      expect(wrapper.findComponent(CiCdAnalyticsCharts).exists()).toBe(true);
    });

    describe('displays individual correctly', () => {
      it('renders with the correct data', () => {
        const charts = wrapper.findComponent(CiCdAnalyticsCharts);
        expect(charts.props()).toEqual(
          expect.objectContaining({
            charts: wrapper.vm.areaCharts,
            chartOptions: wrapper.vm.$options.areaChartOptions,
            loading: false,
          }),
        );
      });
    });
  });
});
