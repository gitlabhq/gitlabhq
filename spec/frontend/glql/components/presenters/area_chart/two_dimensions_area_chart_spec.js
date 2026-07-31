import { GlAreaChart } from '@gitlab/ui/src/charts';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TwoDimensionsAreaChart from '~/glql/components/presenters/area_chart/two_dimensions_area_chart.vue';
import { chartTooltipStub } from '../../../chart_helpers';

const PRIMARY_DIM = { key: 'week', label: 'Week', name: 'week', type: 'dimension' };
const SECONDARY_DIM = { key: 'language', label: 'Language', name: 'language', type: 'dimension' };
const METRIC = { key: 'totalCount', label: 'Total count', name: 'totalCount', type: 'metric' };
const DATA = {
  nodes: [
    { week: '2026-W23', language: 'ruby', totalCount: 12 },
    { week: '2026-W23', language: 'python', totalCount: 6 },
    { week: '2026-W24', language: 'ruby', totalCount: 6 },
    { week: '2026-W24', language: 'python', totalCount: 5 },
  ],
};

describe('TwoDimensionsAreaChart', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(TwoDimensionsAreaChart, {
      propsData: {
        data: DATA,
        primaryDimension: PRIMARY_DIM,
        secondaryDimension: SECONDARY_DIM,
        metric: METRIC,
        ...props,
      },
    });
  };

  const findChart = () => wrapper.findComponent(GlAreaChart);

  beforeEach(() => {
    createComponent();
  });

  it('stacks one series per secondary dimension value over the primary dimension', () => {
    expect(findChart().props('data')).toEqual([
      {
        name: 'ruby',
        stack: 'secondary-dimension',
        data: [
          ['2026-W23', 12],
          ['2026-W24', 6],
        ],
      },
      {
        name: 'python',
        stack: 'secondary-dimension',
        data: [
          ['2026-W23', 6],
          ['2026-W24', 5],
        ],
      },
    ]);
  });

  it('labels the axes from both dimensions and the metric', () => {
    expect(findChart().props('option').xAxis).toMatchObject({
      name: 'Week by Language',
      type: 'category',
    });
    expect(findChart().props('option').yAxis.name).toBe('Total count');
  });

  it('disables legend avg/max', () => {
    expect(findChart().props('includeLegendAvgMax')).toBe(false);
  });

  describe('y-axis formatting', () => {
    const yAxisOption = () => findChart().props('option').yAxis;

    it('uses compact count notation', () => {
      expect(yAxisOption().axisLabel.formatter(2500000)).toBe('2.5M');
    });

    it('formats the y-axis as a compact duration when the metric is a quantile', () => {
      createComponent({
        metric: {
          key: 'durationQuantile',
          label: 'p95',
          name: 'durationQuantile',
          type: 'metric',
        },
      });

      expect(yAxisOption().axisLabel.formatter(10000)).toBe('2.8h');
    });
  });

  describe('with an unaliased parameterised metric', () => {
    it('uses the parameterised label as the y-axis title', () => {
      createComponent({
        metric: {
          key: 'durationQuantile',
          field: 'durationQuantile',
          label: 'Duration quantile',
          type: 'metric',
          parameters: { quantile: 0.5 },
        },
      });

      expect(findChart().props('option').yAxis.name).toBe('Duration quantile (0.5)');
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

    it('uses the alias label as-is for the y-axis title', () => {
      createComponent({ metric: ALIASED_METRIC });

      expect(findChart().props('option').yAxis.name).toBe('Duration P50');
    });

    it('resolves the y-axis formatter from the base field name, not the alias', () => {
      createComponent({ metric: ALIASED_METRIC });

      expect(findChart().props('option').yAxis.axisLabel.formatter(10000)).toBe('2.8h');
    });

    it('formats tooltip values with the base field formatter', () => {
      const w = mountExtended(TwoDimensionsAreaChart, {
        propsData: {
          data: { nodes: [{ week: '2026-W23', language: 'ruby', p50: 3661 }] },
          primaryDimension: PRIMARY_DIM,
          secondaryDimension: SECONDARY_DIM,
          metric: ALIASED_METRIC,
        },
        stubs: {
          GlAreaChart: chartTooltipStub({
            seriesData: [{ seriesName: 'ruby', value: ['2026-W23', 3661], color: '#aaa' }],
          }),
        },
      });

      expect(w.text()).toContain('1h 1m 1s');
    });
  });

  describe('rendered tooltip', () => {
    it('formats tooltip values with the metric unit, regardless of series label', () => {
      const w = mountExtended(TwoDimensionsAreaChart, {
        propsData: {
          data: DATA,
          primaryDimension: PRIMARY_DIM,
          secondaryDimension: SECONDARY_DIM,
          metric: METRIC,
        },
        stubs: {
          GlAreaChart: chartTooltipStub({
            seriesData: [
              { seriesName: 'ruby', value: ['2026-W23', 1234], color: '#aaa' },
              { seriesName: 'python', value: ['2026-W23', 567], color: '#bbb' },
            ],
          }),
        },
      });

      expect(w.text()).toContain('1,234');
      expect(w.text()).toContain('567');
    });
  });
});
