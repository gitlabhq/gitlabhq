import { shallowMount } from '@vue/test-utils';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import Component from '~/projects/pipelines/charts/components/app';
import StatisticsList from '~/projects/pipelines/charts/components/statistics_list';
import { counts, timesChartData } from '../mock_data';

describe('ProjectsPipelinesChartsApp', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(Component, {
      propsData: {
        counts,
        timesChartData,
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
      expect(chart.props('data')).toBe(wrapper.vm.timesChartTransformedData);
      expect(chart.props('option')).toBe(wrapper.vm.$options.timesChartOptions);
    });
  });
});
