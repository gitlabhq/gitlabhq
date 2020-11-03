import { shallowMount } from '@vue/test-utils';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import Component from '~/projects/pipelines/charts/components/app.vue';
import StatisticsList from '~/projects/pipelines/charts/components/statistics_list.vue';
import PipelinesAreaChart from '~/projects/pipelines/charts/components/pipelines_area_chart.vue';
import {
  counts,
  timesChartData,
  areaChartData as lastWeekChartData,
  areaChartData as lastMonthChartData,
  lastYearChartData,
} from '../mock_data';

describe('ProjectsPipelinesChartsApp', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(Component, {
      propsData: {
        counts,
        timesChartData,
        lastWeekChartData,
        lastMonthChartData,
        lastYearChartData,
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

      expect(list.exists()).toBeTruthy();
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
      expect(wrapper.findAll(PipelinesAreaChart).length).toBe(3);
    });

    describe('displays individual correctly', () => {
      it('renders with the correct data', () => {
        const charts = wrapper.findAll(PipelinesAreaChart);

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
