import { GlSegmentedControl } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import CiCdAnalyticsAreaChart from '~/vue_shared/components/ci_cd_analytics/ci_cd_analytics_area_chart.vue';
import CiCdAnalyticsCharts from '~/vue_shared/components/ci_cd_analytics/ci_cd_analytics_charts.vue';
import { transformedAreaChartData, chartOptions } from '../mock_data';

const DEFAULT_PROPS = {
  chartOptions,
  charts: [
    {
      range: 'test range 1',
      title: 'title 1',
      data: transformedAreaChartData,
    },
    {
      range: 'test range 2',
      title: 'title 2',
      data: transformedAreaChartData,
    },
    {
      range: 'test range 3',
      title: 'title 3',
      data: transformedAreaChartData,
    },
  ],
};

describe('~/vue_shared/components/ci_cd_analytics/ci_cd_analytics_charts.vue', () => {
  let wrapper;

  const createWrapper = (props = {}) =>
    shallowMount(CiCdAnalyticsCharts, {
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
    });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('segmented control', () => {
    let segmentedControl;

    beforeEach(() => {
      wrapper = createWrapper();
      segmentedControl = wrapper.find(GlSegmentedControl);
    });

    it('should default to the first chart', () => {
      expect(segmentedControl.props('checked')).toBe(0);
    });

    it('should use the title and index as values', () => {
      const options = segmentedControl.props('options');
      expect(options).toHaveLength(3);
      expect(options).toEqual([
        {
          text: 'title 1',
          value: 0,
        },
        {
          text: 'title 2',
          value: 1,
        },
        {
          text: 'title 3',
          value: 2,
        },
      ]);
    });

    it('should select a different chart on change', async () => {
      segmentedControl.vm.$emit('input', 1);

      const chart = wrapper.find(CiCdAnalyticsAreaChart);

      await nextTick();

      expect(chart.props('chartData')).toEqual(transformedAreaChartData);
      expect(chart.text()).toBe('Date range: test range 2');
    });
  });

  it('should not display charts if there are no charts', () => {
    wrapper = createWrapper({ charts: [] });
    expect(wrapper.find(CiCdAnalyticsAreaChart).exists()).toBe(false);
  });
});
