import { GlStackedColumnChart, GlColumnChart } from '@gitlab/ui/src/charts';
import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ColumnChart from '~/glql/components/presenters/column_chart.vue';
import { MOCK_AGGREGATE, MOCK_GROUP_BY, MOCK_AGGREGATED_DATA_MR } from '../../mock_data';

describe('ColumnChart', () => {
  let wrapper;

  const defaultProps = {
    data: MOCK_AGGREGATED_DATA_MR,
    aggregate: MOCK_AGGREGATE,
    groupBy: MOCK_GROUP_BY,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ColumnChart, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('when loading', () => {
    beforeEach(() => {
      createComponent({ loading: true });
    });

    it('displays skeleton loader', () => {
      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
    });

    it('does not display chart components', () => {
      expect(wrapper.findComponent(GlColumnChart).exists()).toBe(false);
      expect(wrapper.findComponent(GlStackedColumnChart).exists()).toBe(false);
    });
  });

  describe('with single dimension (groupBy with one element)', () => {
    beforeEach(() => {
      createComponent({ groupBy: [MOCK_GROUP_BY[0]], aggregate: [MOCK_AGGREGATE[0]] });
    });

    it('renders GlColumnChart', () => {
      const columnChart = wrapper.findComponent(GlColumnChart);
      expect(columnChart.exists()).toBe(true);
    });

    it('does not render GlStackedColumnChart', () => {
      expect(wrapper.findComponent(GlStackedColumnChart).exists()).toBe(false);
    });

    it('passes correct axis titles to GlColumnChart', () => {
      const columnChart = wrapper.findComponent(GlColumnChart);

      expect(columnChart.props('xAxisTitle')).toBe('Date merged');
      expect(columnChart.props('yAxisTitle')).toBe('Total count');
      expect(columnChart.props('xAxisType')).toBe('category');
    });

    it('passes chart data with correct structure', () => {
      const columnChart = wrapper.findComponent(GlColumnChart);
      const bars = columnChart.props('bars');

      expect(bars).toEqual([
        {
          name: 'Total count',
          data: [
            ['2025-05-01', 2],
            ['2025-05-05', 1],
          ],
        },
      ]);
    });

    describe('with secondary metric', () => {
      beforeEach(() => {
        createComponent({
          groupBy: [MOCK_GROUP_BY[0]],
          aggregate: MOCK_AGGREGATE,
        });
      });

      it('passes secondary data to chart', () => {
        const columnChart = wrapper.findComponent(GlColumnChart);

        expect(columnChart.props('secondaryDataTitle')).toBe('Total time to merge');

        const secondaryData = columnChart.props('secondaryData');
        expect(secondaryData).toHaveLength(1);
        expect(secondaryData[0].name).toBe('Total time to merge');
        expect(secondaryData[0].data).toEqual([
          ['2025-05-01', 120],
          ['2025-05-05', 60],
        ]);
      });
    });
  });

  describe('with two dimensions (groupBy with two elements)', () => {
    beforeEach(() => {
      createComponent({
        groupBy: MOCK_GROUP_BY,
        aggregate: [MOCK_AGGREGATE[0]],
      });
    });

    it('renders GlStackedColumnChart', () => {
      const stackedChart = wrapper.findComponent(GlStackedColumnChart);
      expect(stackedChart.exists()).toBe(true);
    });

    it('does not render GlColumnChart', () => {
      expect(wrapper.findComponent(GlColumnChart).exists()).toBe(false);
    });

    it('passes correct axis configuration to GlStackedColumnChart', () => {
      const stackedChart = wrapper.findComponent(GlStackedColumnChart);

      expect(stackedChart.props('xAxisType')).toBe('category');
      expect(stackedChart.props('xAxisTitle')).toBe('Date merged');
      expect(stackedChart.props('yAxisTitle')).toBe('Total count');
      expect(stackedChart.props('includeLegendAvgMax')).toBe(false);
    });

    it('passes correct group data to stacked chart', () => {
      const stackedChart = wrapper.findComponent(GlStackedColumnChart);

      expect(stackedChart.props('groupBy')).toEqual(['2025-05-01', '2025-05-05']);
      expect(stackedChart.props('bars')).toEqual([
        { name: 'i-user-1-1749491956', data: [2] },
        { name: 'i-user-2-1749491956', data: [1] },
      ]);
    });

    it('uses tiled presentation', () => {
      const stackedChart = wrapper.findComponent(GlStackedColumnChart);
      expect(stackedChart.props('presentation')).toBe('tiled');
    });

    describe('with secondary metric', () => {
      beforeEach(() => {
        createComponent({
          groupBy: MOCK_GROUP_BY,
          aggregate: MOCK_AGGREGATE,
        });
      });

      it('uses stacked presentation', () => {
        const stackedChart = wrapper.findComponent(GlStackedColumnChart);
        expect(stackedChart.props('presentation')).toBe('stacked');
      });

      it('passes secondary data to chart', () => {
        const columnChart = wrapper.findComponent(GlStackedColumnChart);

        expect(columnChart.props('secondaryDataTitle')).toBe('Total time to merge');

        const secondaryData = columnChart.props('secondaryData');
        expect(secondaryData).toEqual([
          { name: 'i-user-1-1749491956', data: [120] },
          { name: 'i-user-2-1749491956', data: [60] },
        ]);
      });
    });
  });

  describe('with no dimensions', () => {
    beforeEach(() => {
      createComponent({ groupBy: [] });
    });

    it('does not render any chart component', () => {
      expect(wrapper.findComponent(GlColumnChart).exists()).toBe(false);
      expect(wrapper.findComponent(GlStackedColumnChart).exists()).toBe(false);
    });
  });

  describe('with no aggregate', () => {
    beforeEach(() => {
      createComponent({ aggregate: [] });
    });

    it('does not render any chart component', () => {
      expect(wrapper.findComponent(GlColumnChart).exists()).toBe(false);
      expect(wrapper.findComponent(GlStackedColumnChart).exists()).toBe(false);
    });
  });

  describe('with empty data', () => {
    beforeEach(() => {
      createComponent({
        data: { nodes: [] },
        groupBy: [MOCK_GROUP_BY[0]],
      });
    });

    it('still renders appropriate chart component', () => {
      expect(wrapper.findComponent(GlColumnChart).exists()).toBe(true);
    });

    it('passes empty data arrays to chart', () => {
      const columnChart = wrapper.findComponent(GlColumnChart);
      const bars = columnChart.props('bars');

      expect(bars).toEqual([]);
    });
  });

  describe('time dimension formatting', () => {
    const mockDataWithDifferentTimeUnits = {
      nodes: [
        {
          ...MOCK_AGGREGATED_DATA_MR.nodes[0],
          mergedAt: {
            ...MOCK_AGGREGATED_DATA_MR.nodes[0].mergedAt,
            range: { from: '2025-01-01', to: '2025-01-31' },
          },
        },
      ],
    };

    it('formats monthly time segments correctly', () => {
      const monthlyGroupBy = [
        {
          fn: { quantity: 1, unit: 'm', timeSegmentType: 'fromStartOfUnit', type: 'time' },
          field: { key: 'mergedAt', name: 'mergedAt', label: 'Month' },
        },
      ];

      createComponent({
        data: mockDataWithDifferentTimeUnits,
        groupBy: monthlyGroupBy,
        aggregate: [MOCK_AGGREGATE[0]],
      });

      const columnChart = wrapper.findComponent(GlColumnChart);
      const bars = columnChart.props('bars');

      expect(bars[0].data[0][0]).toBe('Jan 25'); // Month format
    });

    it('formats yearly time segments correctly', () => {
      const yearlyGroupBy = [
        {
          fn: { quantity: 1, unit: 'y', timeSegmentType: 'fromStartOfUnit', type: 'time' },
          field: { key: 'mergedAt', name: 'mergedAt', label: 'Year' },
        },
      ];

      createComponent({
        data: mockDataWithDifferentTimeUnits,
        groupBy: yearlyGroupBy,
        aggregate: [MOCK_AGGREGATE[0]],
      });

      const columnChart = wrapper.findComponent(GlColumnChart);
      const bars = columnChart.props('bars');

      expect(bars[0].data[0][0]).toBe('2025'); // Year format
    });
  });

  describe('user dimension formatting', () => {
    it('displays user reference values correctly', () => {
      createComponent({ groupBy: MOCK_GROUP_BY });

      const stackedChart = wrapper.findComponent(GlStackedColumnChart);
      const bars = stackedChart.props('bars');

      expect(bars).toHaveLength(2);
      expect(bars[0].name).toBe('i-user-1-1749491956');
      expect(bars[1].name).toBe('i-user-2-1749491956');
    });
  });
});
