import { GlLineChart } from '@gitlab/ui/src/charts';
import { GlSkeletonLoader } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LineChartPresenter from '~/glql/components/presenters/line_chart.vue';

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

describe('LineChartPresenter', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(LineChartPresenter, {
      propsData: {
        data: DATA,
        fields: [DIMENSION, TOTAL_COUNT],
        ...props,
      },
    });
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findLineChart = () => wrapper.findComponent(GlLineChart);

  describe('loading state', () => {
    beforeEach(() => {
      createComponent({ loading: true });
    });

    it('renders the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('does not render the chart', () => {
      expect(findLineChart().exists()).toBe(false);
    });
  });

  describe('with empty data', () => {
    it('renders the chart with no series when nodes is empty', () => {
      createComponent({ data: { nodes: [] } });

      expect(findLineChart().exists()).toBe(true);
      expect(findLineChart().props('data')).toEqual([]);
    });
  });

  describe('with 1 metric', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GlLineChart', () => {
      expect(findLineChart().exists()).toBe(true);
    });

    it('passes the correct data with a single series', () => {
      expect(findLineChart().props('data')).toEqual([
        {
          name: 'Total count',
          data: [
            ['ruby', 21],
            ['python', 14],
          ],
        },
      ]);
    });

    it('sets the x-axis title from the dimension label', () => {
      expect(findLineChart().props('option').xAxis.name).toBe('Language');
    });

    it('disables legend avg/max', () => {
      expect(findLineChart().props('includeLegendAvgMax')).toBe(false);
    });
  });

  describe('with 2 metrics', () => {
    beforeEach(() => {
      createComponent({ fields: [DIMENSION, TOTAL_COUNT, ACCEPTANCE_RATE] });
    });

    it('renders GlLineChart with two series', () => {
      expect(findLineChart().props('data')).toEqual([
        {
          name: 'Total count',
          data: [
            ['ruby', 21],
            ['python', 14],
          ],
        },
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

  describe('with 3+ metrics', () => {
    beforeEach(() => {
      createComponent({ fields: [DIMENSION, SHOWN, ACCEPTED, REJECTED] });
    });

    it('renders GlLineChart with three series', () => {
      const series = findLineChart().props('data');
      expect(series).toHaveLength(3);
      expect(series.map((s) => s.name)).toEqual(['Shown', 'Accepted', 'Rejected']);
    });
  });

  describe('validation', () => {
    const findEmittedErrorMessage = () => wrapper.emitted('error')?.[0]?.[0]?.message;

    it('emits error when there are no dimensions', () => {
      createComponent({
        fields: [{ key: 'totalCount', label: 'Total count', name: 'totalCount', type: 'metric' }],
      });

      expect(findEmittedErrorMessage()).toBe('lineChart requires at least one dimension');
      expect(findLineChart().exists()).toBe(false);
    });

    it('emits error when there are more than 1 dimension', () => {
      createComponent({
        fields: [
          { key: 'a', label: 'A', name: 'a', type: 'dimension' },
          { key: 'b', label: 'B', name: 'b', type: 'dimension' },
          { key: 'm', label: 'M', name: 'm', type: 'metric' },
        ],
      });

      expect(findEmittedErrorMessage()).toBe('lineChart supports exactly one dimension');
      expect(findLineChart().exists()).toBe(false);
    });

    it('emits error when there are no metrics', () => {
      createComponent({
        fields: [{ key: 'language', label: 'Language', name: 'language', type: 'dimension' }],
      });

      expect(findEmittedErrorMessage()).toBe('lineChart requires at least one metric');
      expect(findLineChart().exists()).toBe(false);
    });

    it('does not emit error and does not render chart before fields are populated', () => {
      createComponent({ fields: [] });

      expect(wrapper.emitted('error')).toBeUndefined();
      expect(findLineChart().exists()).toBe(false);
    });
  });

  describe('y-axis title', () => {
    const yAxisName = () => findLineChart().props('option').yAxis?.name;

    it('uses the metric label as the y-axis title for a single metric', () => {
      createComponent();

      expect(yAxisName()).toBe('Total count');
    });

    it('uses the unit label when multiple metrics share the same unit', () => {
      createComponent({ fields: [DIMENSION, SHOWN, ACCEPTED, REJECTED] });

      expect(yAxisName()).toBe('Count');
    });

    it('uses the unit label for rate metrics', () => {
      createComponent({ fields: [DIMENSION, SUCCESS_RATE, FAILURE_RATE] });

      expect(yAxisName()).toBe('Percentage');
    });

    it('omits the y-axis title when metrics have mixed units', () => {
      createComponent({ fields: [DIMENSION, TOTAL_COUNT, ACCEPTANCE_RATE] });

      expect(findLineChart().props('option').yAxis).toBeUndefined();
    });
  });

  describe('y-axis formatting', () => {
    const yAxisOption = () => findLineChart().props('option').yAxis;

    it('formats the y-axis with the compact count formatter', () => {
      createComponent();

      expect(yAxisOption().axisLabel.formatter(2500000)).toBe('2.5M');
    });

    it('formats the y-axis as a percentage when the metric is a rate', () => {
      createComponent({ fields: [DIMENSION, ACCEPTANCE_RATE] });

      expect(yAxisOption().axisLabel.formatter(0.42)).toBe('42%');
    });

    it('formats the y-axis as a compact duration when the metric is a quantile', () => {
      createComponent({
        fields: [DIMENSION, DURATION_QUANTILE],
        data: { nodes: [{ language: 'ruby', durationQuantile: 90 }] },
      });

      expect(yAxisOption().axisLabel.formatter(10000)).toBe('2.8h');
    });

    it('applies the shared formatter when all metrics share a unit', () => {
      createComponent({ fields: [DIMENSION, SUCCESS_RATE, FAILURE_RATE] });

      expect(yAxisOption().axisLabel.formatter(0.42)).toBe('42%');
    });

    it('applies the shared compact count formatter when multiple count metrics are present', () => {
      createComponent({ fields: [DIMENSION, SHOWN, ACCEPTED, REJECTED] });

      expect(yAxisOption().axisLabel.formatter(1500000)).toBe('1.5M');
    });

    it('omits the y-axis formatter when metrics have mixed units', () => {
      createComponent({ fields: [DIMENSION, TOTAL_COUNT, ACCEPTANCE_RATE] });

      expect(findLineChart().props('option').yAxis).toBeUndefined();
    });
  });

  describe('rendered tooltip', () => {
    const chartStub = (testParams) => ({
      template: `<div><slot name="tooltip-content" :params="params"/></div>`,
      data: () => ({ params: testParams }),
    });

    const mountWithTooltip = ({ metrics, seriesData, data = DATA }) => {
      const stub = chartStub({ seriesData });
      return mountExtended(LineChartPresenter, {
        propsData: { data, fields: [DIMENSION, ...metrics] },
        stubs: { GlLineChart: stub },
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

    it('formats tooltip values per-series with scalar params', () => {
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
