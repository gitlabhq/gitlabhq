import { shallowMount } from '@vue/test-utils';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import StatisticsList from '~/projects/pipelines/charts/components/statistics_list.vue';
import CiCdAnalyticsAreaChart from '~/projects/pipelines/charts/components/ci_cd_analytics_area_chart.vue';
import PipelineCharts from '~/projects/pipelines/charts/components/pipeline_charts.vue';
import {
  counts,
  timesChartData as timesChart,
  areaChartData as lastWeek,
  areaChartData as lastMonth,
  lastYearChartData as lastYear,
} from '../mock_data';

describe('ProjectsPipelinesChartsApp', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(PipelineCharts, {
      propsData: {
        counts,
        timesChart,
        lastWeek,
        lastMonth,
        lastYear,
      },
      provide: {
        projectPath: 'test/project',
        shouldRenderDeploymentFrequencyCharts: true,
      },
      stubs: {
        DeploymentFrequencyCharts: true,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('overall statistics', () => {
    it('displays the statistics list', () => {
      const list = wrapper.find(StatisticsList);

      expect(list.exists()).toBe(true);
      expect(list.props('counts')).toBe(counts);
    });

    it('displays the commit duration chart', () => {
      const chart = wrapper.find(GlColumnChart);

      expect(chart.exists()).toBeTruthy();
      expect(chart.props('yAxisTitle')).toBe('Minutes');
      expect(chart.props('xAxisTitle')).toBe('Commit');
      expect(chart.props('bars')).toBe(wrapper.vm.timesChartTransformedData);
      expect(chart.props('option')).toBe(wrapper.vm.$options.timesChartOptions);
    });
  });

  describe('pipelines charts', () => {
    it('displays 3 area charts', () => {
      expect(wrapper.findAll(CiCdAnalyticsAreaChart)).toHaveLength(3);
    });

    describe('displays individual correctly', () => {
      it('renders with the correct data', () => {
        const charts = wrapper.findAll(CiCdAnalyticsAreaChart);
        for (let i = 0; i < charts.length; i += 1) {
          const chart = charts.at(i);

          expect(chart.exists()).toBeTruthy();
          expect(chart.props('chartData')).toBe(wrapper.vm.areaCharts[i].data);
          expect(chart.text()).toBe(wrapper.vm.areaCharts[i].title);
        }
      });
    });
  });
});
