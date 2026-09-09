import { GlChart } from '@gitlab/ui/src/charts';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective } from 'helpers/vue_mock_directive';
import DivergingBarChart from '~/analytics/analytics_dashboards/components/visualizations/diverging_bar_chart.vue';

describe('DivergingBarChart', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const rows = [
    { name: 'Power (100+)', values: [107, 3467] },
    { name: 'Heavy (25–99)', values: [288, 2111] },
    { name: 'Light (1–4)', values: [531, 172] },
  ];

  const seriesNames = ['Share of users', 'Share of sessions'];

  const findChart = () => wrapper.findComponent(GlChart);
  const chartOptions = () => findChart().props('options');
  const seriesAt = (index) => chartOptions().series[index];
  const xAxisAt = (index) => chartOptions().xAxis[index];
  // yAxis: 0 is the centred categories, 1 and 2 the outer value columns.
  const categoryAxis = () => chartOptions().yAxis[0];
  const valueAxisFor = (series) => chartOptions().yAxis[series + 1];
  const valueLabelAt = (series, index) =>
    valueAxisFor(series).axisLabel.formatter(undefined, index);

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(DivergingBarChart, {
      propsData: { data: rows, seriesNames, ...props },
      directives: { GlResizeObserver: createMockDirective('gl-resize-observer') },
    });
  };

  beforeEach(() => createWrapper());

  describe('rows', () => {
    // ECharts draws a category axis bottom-up.
    it('reverses the categories so the given order reads top-down', () => {
      expect(categoryAxis().data).toEqual(['Light (1–4)', 'Heavy (25–99)', 'Power (100+)']);
    });

    it('plots each series against the same reversed rows', () => {
      expect(seriesAt(0).data).toEqual([531, 288, 107]);
      expect(seriesAt(1).data).toEqual([172, 2111, 3467]);
    });

    it('names each series from seriesNames', () => {
      expect([seriesAt(0).name, seriesAt(1).name]).toEqual(seriesNames);
    });
  });

  describe('the two halves', () => {
    it('grows the first series leftward and the second rightward', () => {
      expect(xAxisAt(0).inverse).toBe(true);
      expect(xAxisAt(1).inverse).toBe(false);
    });

    it('meets the two grids at the midpoint', () => {
      expect(chartOptions().grid[0].right).toBe('50%');
      expect(chartOptions().grid[1].left).toBe('50%');
    });

    it('binds each series to its own grid', () => {
      expect(seriesAt(0)).toMatchObject({ xAxisIndex: 0, yAxisIndex: 1 });
      expect(seriesAt(1)).toMatchObject({ xAxisIndex: 1, yAxisIndex: 2 });
    });

    it('ends each half at its largest value', () => {
      expect(xAxisAt(0).max).toBe(531);
      expect(xAxisAt(1).max).toBe(3467);
    });

    it('runs each half past zero to hold the centre clear', () => {
      expect(xAxisAt(0).min).toBeLessThan(0);
      expect(xAxisAt(1).min).toBeLessThan(0);
    });

    it('sizes the centre gap proportionally on both sides', () => {
      expect(xAxisAt(0).min / xAxisAt(0).max).toBeCloseTo(xAxisAt(1).min / xAxisAt(1).max);
    });
  });

  describe('value columns', () => {
    it.each`
      series | index | expected
      ${0}   | ${2}  | ${'107'}
      ${0}   | ${0}  | ${'531'}
      ${1}   | ${2}  | ${'3.5k'}
      ${1}   | ${0}  | ${'172'}
    `('renders $expected for series $series at row $index', ({ series, index, expected }) => {
      expect(valueLabelAt(series, index)).toBe(expected);
    });

    it('puts each column in the outer gutter', () => {
      expect(valueAxisFor(0).position).toBe('left');
      expect(valueAxisFor(1).position).toBe('right');
    });

    it('applies a per-series formatter when given', () => {
      createWrapper({
        valueFormatters: [(value) => `${value} users`, (value) => `${value} sessions`],
      });

      expect(valueLabelAt(0, 2)).toBe('107 users');
      expect(valueLabelAt(1, 2)).toBe('3467 sessions');
    });

    it('renders thousands as a lowercase k', () => {
      createWrapper({ data: [{ name: 'Chat', values: [2570, 1200000] }] });

      expect(valueLabelAt(0, 0)).toBe('2.6k');
      expect(valueLabelAt(1, 0)).toBe('1.2M');
    });
  });

  describe('chrome', () => {
    it('centres the category labels on the midpoint', () => {
      expect(categoryAxis().axisLabel).toMatchObject({ align: 'center', margin: 0 });
      expect(categoryAxis().position).toBe('right');
    });

    it('hides both value axes', () => {
      expect(xAxisAt(0).show).toBe(false);
      expect(xAxisAt(1).show).toBe(false);
    });

    it('draws each bar against a track', () => {
      expect(seriesAt(0).showBackground).toBe(true);
      expect(seriesAt(1).showBackground).toBe(true);
    });

    it('gives the two series different colours', () => {
      expect(seriesAt(0).itemStyle.color).not.toBe(seriesAt(1).itemStyle.color);
    });

    // ECharts builds the legend from the series names.
    it('legends the two series', () => {
      expect(chartOptions().legend.bottom).toBe(0);
      expect(chartOptions().series.map(({ name }) => name)).toEqual(seriesNames);
    });

    // Regression: the track spans the whole grid and covered the labels at the default z.
    it('draws the axes above the bar tracks', () => {
      const barSeriesZ = 2;

      expect(categoryAxis().z).toBeGreaterThan(barSeriesZ);
      expect(valueAxisFor(0).z).toBeGreaterThan(barSeriesZ);
      expect(valueAxisFor(1).z).toBeGreaterThan(barSeriesZ);
    });

    it('draws the category names once, not on both halves', () => {
      expect(chartOptions().yAxis).toHaveLength(3);
    });
  });

  describe('with a row missing a value', () => {
    beforeEach(() => createWrapper({ data: [{ name: 'Power (100+)', values: [107] }] }));

    it('plots and labels the gap as zero', () => {
      expect(seriesAt(1).data).toEqual([0]);
      expect(valueLabelAt(1, 0)).toBe('0');
    });
  });

  describe('without data', () => {
    beforeEach(() => createWrapper({ data: undefined }));

    it('renders an empty chart rather than erroring', () => {
      expect(categoryAxis().data).toEqual([]);
      expect(seriesAt(0).data).toEqual([]);
      expect(seriesAt(1).data).toEqual([]);
    });

    it('keeps the axes at a usable scale', () => {
      expect(xAxisAt(0).max).toBeGreaterThan(0);
      expect(xAxisAt(0).min).toBeLessThan(0);
    });
  });

  describe('options passthrough', () => {
    beforeEach(() => createWrapper({ options: { legend: { show: false } } }));

    it('merges caller options over the defaults', () => {
      expect(chartOptions().legend.show).toBe(false);
    });

    it('keeps the defaults it does not override', () => {
      expect(xAxisAt(0).inverse).toBe(true);
    });
  });
});
