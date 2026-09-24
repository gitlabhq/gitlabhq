import { GlBarChart } from '@gitlab/ui/src/charts';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TwoDimensionsBarChart from '~/glql/components/presenters/bar_chart/two_dimensions_bar_chart.vue';
import {
  barCategoryAxisOptions,
  barChartHeightFor,
} from '~/glql/components/presenters/bar_chart/bar_chart_options';
import { chartTooltipStub } from '../../../chart_helpers';

const PRIMARY_DIM = { key: 'user', label: 'User', name: 'user', type: 'dimension' };
const SECONDARY_DIM = { key: 'language', label: 'Language', name: 'language', type: 'dimension' };
const METRIC = { key: 'totalCount', label: 'Total count', name: 'totalCount', type: 'metric' };
const DATA = {
  nodes: [
    { user: 'u0', language: 'ruby', totalCount: 12 },
    { user: 'u0', language: 'python', totalCount: 6 },
    { user: 'u2', language: 'ruby', totalCount: 6 },
    { user: 'u2', language: 'python', totalCount: 5 },
  ],
};

describe('TwoDimensionsBarChart', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(TwoDimensionsBarChart, {
      propsData: {
        data: DATA,
        primaryDimension: PRIMARY_DIM,
        secondaryDimension: SECONDARY_DIM,
        metric: METRIC,
        ...props,
      },
    });
  };

  const findChart = () => wrapper.findComponent(GlBarChart);

  beforeEach(() => {
    createComponent();
  });

  it('renders GlBarChart with stacked presentation', () => {
    expect(findChart().exists()).toBe(true);
    expect(findChart().props('presentation')).toBe('stacked');
  });

  it('sizes the chart from the number of primary-dimension rows', () => {
    expect(findChart().props('height')).toBe(barChartHeightFor(2));
  });

  it('labels the axes from the metric and both dimensions', () => {
    expect(findChart().props('xAxisTitle')).toBe('Total count');
    expect(findChart().props('yAxisTitle')).toBe('User by Language');
  });

  it('builds one series per secondary-dimension value, with points carrying their own category label', () => {
    expect(findChart().props('data')).toEqual({
      ruby: [
        [12, 'u0'],
        [6, 'u2'],
      ],
      python: [
        [6, 'u0'],
        [5, 'u2'],
      ],
    });
  });

  it('leaves pairs with no row empty rather than zero', () => {
    createComponent({ data: { nodes: DATA.nodes.slice(0, 3) } });

    expect(findChart().props('data').python).toEqual([
      [6, 'u0'],
      [null, 'u2'],
    ]);
  });

  describe('with showAxisTitles=false', () => {
    beforeEach(() => {
      createComponent({ showAxisTitles: false });
    });

    it('passes empty axis titles', () => {
      expect(findChart().props('xAxisTitle')).toBe('');
      expect(findChart().props('yAxisTitle')).toBe('');
    });

    it('drops the axis title space from the grid', () => {
      const { grid } = barCategoryAxisOptions(['u0', 'u2'], { axisTitle: false });

      expect(findChart().props('option').grid).toEqual(grid);
    });

    it('sizes the chart without room for an axis title', () => {
      expect(findChart().props('height')).toBe(barChartHeightFor(2, { axisTitle: false }));
    });
  });

  describe('x-axis formatting', () => {
    const xAxisOption = () => findChart().props('option').xAxis;

    it('uses compact count notation', () => {
      expect(xAxisOption().axisLabel.formatter(2500000)).toBe('2.5M');
    });

    it('formats the x-axis as a compact duration when the metric is a quantile', () => {
      createComponent({
        metric: {
          key: 'durationQuantile',
          label: 'p95',
          name: 'durationQuantile',
          type: 'metric',
        },
      });

      expect(xAxisOption().axisLabel.formatter(10000)).toBe('2.8h');
    });
  });

  describe('y-axis category labels', () => {
    it('overrides the truncating label formatter and sizes the gutter from the groups', () => {
      // Long enough to exceed the minimum width clamp, so this asserts the
      // gutter is really derived from the groups, not just the clamp floor.
      wrapper = shallowMountExtended(TwoDimensionsBarChart, {
        propsData: {
          data: {
            nodes: [
              { user: 'a-very-long-username', language: 'ruby', totalCount: 12 },
              { user: 'u2', language: 'ruby', totalCount: 6 },
            ],
          },
          primaryDimension: PRIMARY_DIM,
          secondaryDimension: SECONDARY_DIM,
          metric: METRIC,
        },
      });

      const option = findChart().props('option');
      const { yAxis, grid } = barCategoryAxisOptions(['a-very-long-username', 'u2']);

      expect(option.yAxis.axisLabel.formatter('Jan 1, 2026')).toBe('Jan 1, 2026');
      expect(option.yAxis.axisLabel.width).toBe(yAxis.axisLabel.width);
      expect(option.yAxis.nameGap).toBe(yAxis.nameGap);
      expect(option.grid).toEqual(grid);
      // the x-axis formatter in the same option object still applies
      expect(option.xAxis.axisLabel.formatter(2500000)).toBe('2.5M');
    });
  });

  describe('with a time dimension', () => {
    it('includes granularity in the y-axis title', () => {
      const timeDim = {
        key: 'finished',
        label: 'Finished',
        name: 'finishedAt',
        type: 'dimension',
        parameters: { granularity: 'monthly' },
      };

      createComponent({ primaryDimension: timeDim });

      expect(findChart().props('yAxisTitle')).toBe('Finished (monthly) by Language');
    });
  });

  describe('with an unaliased parameterised metric', () => {
    const PARAMETERISED_METRIC = {
      key: 'durationQuantile',
      field: 'durationQuantile',
      label: 'Duration quantile',
      type: 'metric',
      parameters: { quantile: 0.5 },
    };

    it('uses the parameterised label as the x-axis title', () => {
      createComponent({ metric: PARAMETERISED_METRIC });

      expect(findChart().props('xAxisTitle')).toBe('Duration quantile (0.5)');
    });
  });

  describe('with an aliased parameterised metric', () => {
    const ALIASED_METRIC = {
      key: 'p50',
      field: 'durationQuantile',
      label: 'Duration P50',
      type: 'metric',
      parameters: { quantile: 0.5 },
    };

    it('resolves the formatter from the base field name, not the alias', () => {
      createComponent({ metric: ALIASED_METRIC });

      expect(findChart().props('option').xAxis.axisLabel.formatter(10000)).toBe('2.8h');
    });

    it('uses the alias label as-is for the x-axis title', () => {
      createComponent({ metric: ALIASED_METRIC });

      expect(findChart().props('xAxisTitle')).toBe('Duration P50');
    });
  });

  describe('rendered tooltip', () => {
    it('formats tooltip values with the metric unit, regardless of series label', () => {
      const w = mountExtended(TwoDimensionsBarChart, {
        propsData: {
          data: DATA,
          primaryDimension: PRIMARY_DIM,
          secondaryDimension: SECONDARY_DIM,
          metric: METRIC,
        },
        stubs: {
          GlBarChart: chartTooltipStub({
            seriesData: [
              { seriesName: 'ruby', value: [1234, 'u0'], color: '#aaa' },
              { seriesName: 'python', value: [567, 'u0'], color: '#bbb' },
            ],
          }),
        },
      });

      expect(w.text()).toContain('1,234');
      expect(w.text()).toContain('567');
    });

    it('omits padded pairs but keeps genuine zeros', () => {
      const w = mountExtended(TwoDimensionsBarChart, {
        propsData: {
          data: DATA,
          primaryDimension: PRIMARY_DIM,
          secondaryDimension: SECONDARY_DIM,
          metric: METRIC,
        },
        stubs: {
          GlBarChart: chartTooltipStub({
            seriesData: [
              { seriesName: 'ruby', value: [0, 'u0'], color: '#aaa' },
              { seriesName: 'python', value: [null, 'u0'], color: '#bbb' },
            ],
          }),
        },
      });

      expect(w.text()).toContain('ruby');
      expect(w.text()).not.toContain('python');
    });

    it('still names the dimensions in the title when axis titles are hidden', () => {
      const w = mountExtended(TwoDimensionsBarChart, {
        propsData: {
          data: DATA,
          primaryDimension: PRIMARY_DIM,
          secondaryDimension: SECONDARY_DIM,
          metric: METRIC,
          showAxisTitles: false,
        },
        stubs: {
          GlBarChart: chartTooltipStub({
            seriesData: [{ seriesName: 'ruby', value: [12, 'u0'], color: '#aaa' }],
          }),
        },
      });

      expect(w.text()).toContain('u0 (User by Language)');
    });
  });
});
