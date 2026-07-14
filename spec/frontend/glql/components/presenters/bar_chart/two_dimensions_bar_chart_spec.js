import { GlBarChart } from '@gitlab/ui/src/charts';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TwoDimensionsBarChart from '~/glql/components/presenters/bar_chart/two_dimensions_bar_chart.vue';

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

  const createComponent = () => {
    wrapper = shallowMountExtended(TwoDimensionsBarChart, {
      propsData: {
        data: DATA,
        primaryDimension: PRIMARY_DIM,
        secondaryDimension: SECONDARY_DIM,
        metric: METRIC,
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

  describe('x-axis formatting', () => {
    const xAxisOption = () => findChart().props('option').xAxis;

    it('uses compact count notation', () => {
      expect(xAxisOption().axisLabel.formatter(2500000)).toBe('2.5M');
    });

    it('formats the x-axis as a compact duration when the metric is a quantile', () => {
      wrapper = shallowMountExtended(TwoDimensionsBarChart, {
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

      expect(xAxisOption().axisLabel.formatter(10000)).toBe('2.8h');
    });
  });

  describe('rendered tooltip', () => {
    const chartStub = (testParams) => ({
      template: `<div><slot name="tooltip-content" :params="params"/></div>`,
      data: () => ({ params: testParams }),
    });

    it('formats tooltip values with the metric unit, regardless of series label', () => {
      const w = mountExtended(TwoDimensionsBarChart, {
        propsData: {
          data: DATA,
          primaryDimension: PRIMARY_DIM,
          secondaryDimension: SECONDARY_DIM,
          metric: METRIC,
        },
        stubs: {
          GlBarChart: chartStub({
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
  });
});
