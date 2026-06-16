import { GlColumnChart, GlStackedColumnChart } from '@gitlab/ui/src/charts';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SingleDimensionColumnChart from '~/glql/components/presenters/column_chart/single_dimension_column_chart.vue';

const DIMENSION = { key: 'language', label: 'Language', name: 'language', type: 'dimension' };
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
const REJECTED = { key: 'rejectedCount', label: 'Rejected', name: 'rejectedCount', type: 'metric' };
const SUCCESS_RATE = {
  key: 'successRate',
  label: 'Success rate',
  name: 'successRate',
  type: 'metric',
};
const FAILURE_RATE = {
  key: 'failureRate',
  label: 'Failure rate',
  name: 'failureRate',
  type: 'metric',
};
const DATA = {
  nodes: [
    {
      language: 'ruby',
      totalCount: 21,
      acceptanceRate: 0.625,
      shownCount: 8,
      acceptedCount: 5,
      rejectedCount: 8,
    },
    {
      language: 'python',
      totalCount: 14,
      acceptanceRate: 0.333,
      shownCount: 6,
      acceptedCount: 2,
      rejectedCount: 6,
    },
  ],
};

describe('SingleDimensionColumnChart', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(SingleDimensionColumnChart, {
      propsData: {
        data: DATA,
        dimension: DIMENSION,
        metrics: [TOTAL_COUNT],
        ...props,
      },
    });
  };

  const findColumnChart = () => wrapper.findComponent(GlColumnChart);
  const findStackedChart = () => wrapper.findComponent(GlStackedColumnChart);

  describe('with 1 metric', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GlColumnChart', () => {
      expect(findColumnChart().exists()).toBe(true);
      expect(findStackedChart().exists()).toBe(false);
    });

    it('labels the y-axis with the metric name', () => {
      expect(findColumnChart().props('yAxisTitle')).toBe('Total count');
    });

    it('passes the primary bar series', () => {
      expect(findColumnChart().props('bars')).toEqual([
        {
          name: 'Total count',
          data: [
            ['ruby', 21],
            ['python', 14],
          ],
        },
      ]);
    });

    it('passes empty secondary data', () => {
      expect(findColumnChart().props('secondaryData')).toEqual([]);
    });
  });

  describe('with 2 metrics (default — dual-axis)', () => {
    beforeEach(() => {
      createComponent({ metrics: [TOTAL_COUNT, ACCEPTANCE_RATE] });
    });

    it('renders GlColumnChart with dual-axis data', () => {
      expect(findColumnChart().exists()).toBe(true);
      expect(findStackedChart().exists()).toBe(false);
    });

    it('labels the left axis with metric[0] and right axis with metric[1]', () => {
      expect(findColumnChart().props('yAxisTitle')).toBe('Total count');
      expect(findColumnChart().props('secondaryDataTitle')).toBe('Acceptance rate');
    });

    it('passes metric[1] as secondary data', () => {
      expect(findColumnChart().props('secondaryData')).toEqual([
        {
          name: 'Acceptance rate',
          data: [
            ['ruby', 0.625],
            ['python', 0.333],
          ],
        },
      ]);
    });
  });

  describe('with 3+ metrics (grouped)', () => {
    beforeEach(() => {
      createComponent({ metrics: [SHOWN, ACCEPTED, REJECTED] });
    });

    it('renders GlStackedColumnChart in tiled presentation', () => {
      expect(findStackedChart().exists()).toBe(true);
      expect(findColumnChart().exists()).toBe(false);
      expect(findStackedChart().props('presentation')).toBe('tiled');
    });

    it('labels the y-axis with the shared unit when all metrics have the same unit', () => {
      expect(findStackedChart().props('yAxisTitle')).toBe('Count');
    });

    it('maps each metric to its own bar series', () => {
      expect(findStackedChart().props('bars')).toEqual([
        { name: 'Shown', data: [8, 6] },
        { name: 'Accepted', data: [5, 2] },
        { name: 'Rejected', data: [8, 6] },
      ]);
    });
  });

  describe('with 2 metrics and stacked=true', () => {
    beforeEach(() => {
      createComponent({ metrics: [TOTAL_COUNT, ACCEPTANCE_RATE], stacked: true });
    });

    it('renders GlStackedColumnChart in stacked presentation', () => {
      expect(findStackedChart().exists()).toBe(true);
      expect(findStackedChart().props('presentation')).toBe('stacked');
    });

    it('leaves the y-axis title empty when metrics have mixed units', () => {
      expect(findStackedChart().props('yAxisTitle')).toBe('');
    });
  });

  describe('with 3+ metrics and stacked=true', () => {
    beforeEach(() => {
      createComponent({ metrics: [SHOWN, ACCEPTED, REJECTED], stacked: true });
    });

    it('renders GlStackedColumnChart in stacked presentation', () => {
      expect(findStackedChart().props('presentation')).toBe('stacked');
    });

    it('labels the y-axis with the shared unit', () => {
      expect(findStackedChart().props('yAxisTitle')).toBe('Count');
    });
  });

  describe('y-axis and tooltip formatting', () => {
    const yAxisOption = (chartWrapper) => chartWrapper.props('option').yAxis;

    it('formats the y-axis with the compact count formatter', () => {
      createComponent();

      expect(yAxisOption(findColumnChart()).axisLabel.formatter(2500000)).toBe('2.5M');
    });

    it('formats the y-axis as a compact duration when the metric is a quantile', () => {
      createComponent({
        metrics: [DURATION_QUANTILE],
        data: { nodes: [{ language: 'ruby', durationQuantile: 90 }] },
      });

      expect(yAxisOption(findColumnChart()).axisLabel.formatter(10000)).toBe('2.8h');
    });

    it('formats the y-axis as a percentage when the metric is a rate', () => {
      createComponent({
        metrics: [ACCEPTANCE_RATE],
        data: { nodes: [{ language: 'ruby', acceptanceRate: 0.5 }] },
      });

      expect(yAxisOption(findColumnChart()).axisLabel.formatter(0.42)).toBe('42%');
    });

    it('uses per-axis formatters in dual-axis mode (compact for count, % for rate)', () => {
      createComponent({ metrics: [TOTAL_COUNT, ACCEPTANCE_RATE] });

      const [primaryAxis, secondaryAxis] = yAxisOption(findColumnChart());
      expect(primaryAxis.axisLabel.formatter(2500000)).toBe('2.5M');
      expect(secondaryAxis.axisLabel.formatter(0.5)).toBe('50%');
    });

    it('applies the shared formatter on a stacked chart when all metrics share a unit', () => {
      createComponent({ metrics: [SUCCESS_RATE, FAILURE_RATE], stacked: true });

      const { yAxis } = findStackedChart().props('option');
      expect(Array.isArray(yAxis)).toBe(true);
      expect(yAxis[0].axisLabel.formatter(0.42)).toBe('42%');
    });

    it('also applies the shared (compact) count formatter when 3+ count metrics share a unit', () => {
      createComponent({ metrics: [SHOWN, ACCEPTED, REJECTED] });

      const { yAxis } = findStackedChart().props('option');
      expect(Array.isArray(yAxis)).toBe(true);
      expect(yAxis[0].axisLabel.formatter(1500000)).toBe('1.5M');
    });

    it('omits the y-axis formatter on a stacked chart with mixed units', () => {
      createComponent({ metrics: [SUCCESS_RATE, DURATION_QUANTILE, TOTAL_COUNT] });

      expect(findStackedChart().props('option').yAxis).toBeUndefined();
    });

    it('omits the y-axis formatter for 2 stacked metrics with mixed units', () => {
      createComponent({ metrics: [TOTAL_COUNT, ACCEPTANCE_RATE], stacked: true });

      expect(findStackedChart().props('option').yAxis).toBeUndefined();
    });
  });

  describe('rendered tooltip', () => {
    // Stub the chart and render its `#tooltip-content` slot with fixed params,
    // so we can assert on the resulting tooltip DOM rather than reaching into
    // component internals.
    const chartStub = (testParams) => ({
      template: `<div><slot name="tooltip-content" :params="params"/></div>`,
      data: () => ({ params: testParams }),
    });

    const mountWithTooltip = ({ metrics, stacked = false, seriesData, data = DATA }) => {
      const stub = chartStub({ seriesData });
      return mountExtended(SingleDimensionColumnChart, {
        propsData: { data, dimension: DIMENSION, metrics, stacked },
        stubs: { GlColumnChart: stub, GlStackedColumnChart: stub },
      });
    };

    it('formats each series with its own unit when units differ across metrics', () => {
      const w = mountWithTooltip({
        metrics: [ACCEPTANCE_RATE, DURATION_QUANTILE],
        seriesData: [
          { seriesName: 'Acceptance rate', value: ['ruby', 0.819], color: '#aaa' },
          { seriesName: 'p95', value: ['ruby', 5252], color: '#bbb' },
        ],
      });

      expect(w.text()).toContain('81.9%');
      expect(w.text()).toContain('1h 27m 32s');
    });

    it('renders unknown series labels through identity (no unit mapping)', () => {
      const w = mountWithTooltip({
        metrics: [DURATION_QUANTILE],
        seriesData: [{ seriesName: 'Unknown', value: ['ruby', 3661], color: '#aaa' }],
      });

      expect(w.text()).toContain('3661');
      expect(w.text()).not.toContain('1h 1m 1s');
    });

    it('formats tooltip values per-series on the stacked chart (scalar params)', () => {
      const w = mountWithTooltip({
        metrics: [SHOWN, ACCEPTED, REJECTED],
        seriesData: [
          { seriesName: 'Shown', value: 1234, color: '#aaa' },
          { seriesName: 'Accepted', value: 567, color: '#bbb' },
        ],
      });

      expect(w.text()).toContain('1,234');
      expect(w.text()).toContain('567');
    });
  });
});
