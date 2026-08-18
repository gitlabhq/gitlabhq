import { GlStackedColumnChart } from '@gitlab/ui/src/charts';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TwoDimensionsColumnChart from '~/glql/components/presenters/column_chart/two_dimensions_column_chart.vue';
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

describe('TwoDimensionsColumnChart', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(TwoDimensionsColumnChart, {
      propsData: {
        data: DATA,
        primaryDimension: PRIMARY_DIM,
        secondaryDimension: SECONDARY_DIM,
        metric: METRIC,
        ...props,
      },
    });
  };

  const findChart = () => wrapper.findComponent(GlStackedColumnChart);

  beforeEach(() => {
    createComponent();
  });

  it('renders GlStackedColumnChart with stacked presentation', () => {
    expect(findChart().exists()).toBe(true);
    expect(findChart().props('presentation')).toBe('stacked');
  });

  it('groups by the primary dimension with the secondary dimension as bar names', () => {
    expect(findChart().props('groupBy')).toEqual(['u0', 'u2']);
    expect(findChart().props('bars')).toEqual([
      { name: 'ruby', data: [12, 6] },
      { name: 'python', data: [6, 5] },
    ]);
  });

  it('labels the axes from both dimensions and the metric', () => {
    expect(findChart().props('xAxisTitle')).toBe('User by Language');
    expect(findChart().props('yAxisTitle')).toBe('Total count');
  });

  describe('with a time dimension', () => {
    it('includes granularity in the x-axis title', () => {
      const timeDim = {
        key: 'finished',
        label: 'Finished',
        name: 'finishedAt',
        type: 'dimension',
        parameters: { granularity: 'monthly' },
      };

      createComponent({ primaryDimension: timeDim });

      expect(findChart().props('xAxisTitle')).toBe('Finished (monthly) by Language');
    });
  });

  describe('y-axis and tooltip formatting', () => {
    const yAxisOption = () => findChart().props('option').yAxis;

    it('passes yAxis as an array (so the formatter merges) and uses compact count notation', () => {
      expect(Array.isArray(yAxisOption())).toBe(true);
      expect(yAxisOption()[0].axisLabel.formatter(2500000)).toBe('2.5M');
    });

    it('formats the y-axis as a compact duration when the metric is a quantile', () => {
      wrapper = shallowMountExtended(TwoDimensionsColumnChart, {
        propsData: {
          data: DATA,
          primaryDimension: PRIMARY_DIM,
          secondaryDimension: SECONDARY_DIM,
          metric: {
            key: 'durationQuantile',
            label: 'p95',
            name: 'durationQuantile',
            type: 'metric',
          },
        },
      });

      expect(yAxisOption()[0].axisLabel.formatter(10000)).toBe('2.8h');
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

    it('uses the parameterised label as the y-axis title', () => {
      createComponent({ metric: PARAMETERISED_METRIC });

      expect(findChart().props('yAxisTitle')).toBe('Duration quantile (0.5)');
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

      const { yAxis } = findChart().props('option');
      expect(yAxis[0].axisLabel.formatter(10000)).toBe('2.8h');
    });

    it('uses the alias label as-is for the y-axis title', () => {
      createComponent({ metric: ALIASED_METRIC });

      expect(findChart().props('yAxisTitle')).toBe('Duration P50');
    });
  });

  describe('rendered tooltip', () => {
    it('formats tooltip values with the metric unit, regardless of series label', () => {
      const w = mountExtended(TwoDimensionsColumnChart, {
        propsData: {
          data: DATA,
          primaryDimension: PRIMARY_DIM,
          secondaryDimension: SECONDARY_DIM,
          metric: METRIC,
        },
        stubs: {
          GlStackedColumnChart: chartTooltipStub({
            seriesData: [
              { seriesName: 'ruby', value: ['u0', 1234], color: '#aaa' },
              { seriesName: 'python', value: ['u0', 567], color: '#bbb' },
            ],
          }),
        },
      });

      expect(w.text()).toContain('1,234');
      expect(w.text()).toContain('567');
    });
  });
});
