import { GlBarChart } from '@gitlab/ui/src/charts';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SingleDimensionBarChart from '~/glql/components/presenters/bar_chart/single_dimension_bar_chart.vue';
import { barCategoryAxisOptions } from '~/glql/components/presenters/bar_chart/bar_chart_options';
import { chartTooltipStub } from '../../../chart_helpers';

const DIMENSION = { key: 'language', label: 'Language', name: 'language', type: 'dimension' };
const CREATED = { key: 'created', label: 'Created', name: 'created', type: 'dimension' };
const TOTAL_COUNT = {
  key: 'totalCount',
  label: 'Total count',
  name: 'totalCount',
  type: 'metric',
};
const ACCEPTANCE_RATE = {
  key: 'acceptanceRate',
  label: 'Acceptance rate',
  name: 'acceptanceRate',
  type: 'metric',
};
const DURATION_QUANTILE = {
  key: 'durationQuantile',
  label: 'p95',
  name: 'durationQuantile',
  type: 'metric',
};
const SHOWN = { key: 'shownCount', label: 'Shown', name: 'shownCount', type: 'metric' };
const ACCEPTED = { key: 'acceptedCount', label: 'Accepted', name: 'acceptedCount', type: 'metric' };
const DATA = {
  nodes: [
    { language: 'ruby', totalCount: 21, acceptanceRate: 0.625, shownCount: 8, acceptedCount: 5 },
    { language: 'python', totalCount: 14, acceptanceRate: 0.333, shownCount: 6, acceptedCount: 2 },
  ],
};

describe('SingleDimensionBarChart', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(SingleDimensionBarChart, {
      propsData: {
        data: DATA,
        dimension: DIMENSION,
        metrics: [TOTAL_COUNT],
        ...props,
      },
    });
  };

  const findChart = () => wrapper.findComponent(GlBarChart);

  describe('with 1 metric', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GlBarChart in tiled presentation by default', () => {
      expect(findChart().exists()).toBe(true);
      expect(findChart().props('presentation')).toBe('tiled');
    });

    it('labels the x-axis with the metric name and y-axis with the dimension name', () => {
      expect(findChart().props('xAxisTitle')).toBe('Total count');
      expect(findChart().props('yAxisTitle')).toBe('Language');
    });

    it('passes reversed [value, dimension] tuples keyed by metric label', () => {
      expect(findChart().props('data')).toEqual({
        'Total count': [
          [21, 'ruby'],
          [14, 'python'],
        ],
      });
    });
  });

  describe('with 2 metrics (tiled)', () => {
    beforeEach(() => {
      createComponent({ metrics: [TOTAL_COUNT, ACCEPTANCE_RATE] });
    });

    it('renders GlBarChart in tiled presentation', () => {
      expect(findChart().props('presentation')).toBe('tiled');
    });

    it('passes one series per metric', () => {
      expect(findChart().props('data')).toEqual({
        'Total count': [
          [21, 'ruby'],
          [14, 'python'],
        ],
        'Acceptance rate': [
          [0.625, 'ruby'],
          [0.333, 'python'],
        ],
      });
    });
  });

  describe('with stacked=true', () => {
    beforeEach(() => {
      createComponent({ metrics: [SHOWN, ACCEPTED], stacked: true });
    });

    it('renders GlBarChart in stacked presentation', () => {
      expect(findChart().props('presentation')).toBe('stacked');
    });
  });

  describe('x-axis formatting', () => {
    const xAxisOption = () => findChart().props('option').xAxis;

    it('formats the x-axis with the compact count formatter', () => {
      createComponent();

      expect(xAxisOption().axisLabel.formatter(2500000)).toBe('2.5M');
    });

    it('formats the x-axis as a compact duration when the metric is a quantile', () => {
      createComponent({
        metrics: [DURATION_QUANTILE],
        data: { nodes: [{ language: 'ruby', durationQuantile: 10000 }] },
      });

      expect(xAxisOption().axisLabel.formatter(10000)).toBe('2.8h');
    });

    it('formats the x-axis as a percentage when the metric is a rate', () => {
      createComponent({
        metrics: [ACCEPTANCE_RATE],
        data: { nodes: [{ language: 'ruby', acceptanceRate: 0.5 }] },
      });

      expect(xAxisOption().axisLabel.formatter(0.42)).toBe('42%');
    });

    it('omits the x-axis formatter override when metrics have mixed units', () => {
      createComponent({ metrics: [TOTAL_COUNT, ACCEPTANCE_RATE] });

      expect(findChart().props('option').xAxis).toBeUndefined();
    });
  });

  describe('y-axis category labels', () => {
    const yAxisOption = () => findChart().props('option').yAxis;

    it('overrides the truncating label formatter with pixel-based sizing', () => {
      createComponent();

      expect(yAxisOption().axisLabel.formatter('Jan 1, 2026')).toBe('Jan 1, 2026');
      expect(yAxisOption().axisLabel.overflow).toBe('truncate');
    });

    it('sizes the label gutter from the longest category label', () => {
      createComponent({
        dimension: CREATED,
        data: { nodes: [{ created: '2026-01-01', totalCount: 21 }] },
      });

      // The sizing math itself is covered by bar_chart_options_spec; here we
      // assert the formatted labels reach the util and its output the chart.
      const { yAxis, grid } = barCategoryAxisOptions(['Jan 1, 2026']);

      expect(yAxisOption().axisLabel.width).toBe(yAxis.axisLabel.width);
      expect(yAxisOption().nameGap).toBe(yAxis.nameGap);
      expect(findChart().props('option').grid).toEqual(grid);
    });

    it('formats date-bucket dimension values as localized dates', () => {
      createComponent({
        dimension: CREATED,
        data: {
          nodes: [
            { created: '2026-01-01', totalCount: 21 },
            { created: '2026-02-01', totalCount: 14 },
          ],
        },
      });

      expect(findChart().props('data')).toEqual({
        'Total count': [
          [21, 'Jan 1, 2026'],
          [14, 'Feb 1, 2026'],
        ],
      });
    });
  });

  describe('rendered tooltip', () => {
    // Stub the chart and render its `#tooltip-content` slot with fixed params,
    // so we can assert on the resulting tooltip DOM rather than reaching into
    // component internals.
    const mountWithTooltip = ({ metrics, stacked = false, seriesData, data = DATA }) => {
      const stub = chartTooltipStub({ seriesData });
      return mountExtended(SingleDimensionBarChart, {
        propsData: { data, dimension: DIMENSION, metrics, stacked },
        stubs: { GlBarChart: stub },
      });
    };

    it('formats each series with its own unit when units differ across metrics', () => {
      const w = mountWithTooltip({
        metrics: [ACCEPTANCE_RATE, DURATION_QUANTILE],
        seriesData: [
          { seriesName: 'Acceptance rate', value: [0.819, 'ruby'], color: '#aaa' },
          { seriesName: 'p95', value: [5252, 'ruby'], color: '#bbb' },
        ],
      });

      expect(w.text()).toContain('81.9%');
      expect(w.text()).toContain('1h 27m 32s');
    });

    it('renders unknown series labels through identity (no unit mapping)', () => {
      const w = mountWithTooltip({
        metrics: [DURATION_QUANTILE],
        seriesData: [{ seriesName: 'Unknown', value: [3661, 'ruby'], color: '#aaa' }],
      });

      expect(w.text()).toContain('3661');
      expect(w.text()).not.toContain('1h 1m 1s');
    });
  });
});
