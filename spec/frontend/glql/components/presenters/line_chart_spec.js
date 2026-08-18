import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LineChartPresenter from '~/glql/components/presenters/line_chart.vue';
import DimensionRoutedChart from '~/glql/components/presenters/chart/dimension_routed_chart.vue';
import SingleDimensionSeriesChart from '~/glql/components/presenters/chart/single_dimension_series_chart.vue';

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
const DATA = {
  nodes: [
    { language: 'ruby', totalCount: 21, acceptanceRate: 0.625 },
    { language: 'python', totalCount: 14, acceptanceRate: 0.333 },
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
      // Render the real routing shell (validation/loading covered in
      // dimension_routed_chart_spec.js) while its chart children stay stubbed.
      stubs: { DimensionRoutedChart },
    });
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findSeriesChart = () => wrapper.findComponent(SingleDimensionSeriesChart);

  describe('loading state', () => {
    it('renders the skeleton loader and no chart while loading', () => {
      createComponent({ loading: true });

      expect(findSkeletonLoader().exists()).toBe(true);
      expect(findSeriesChart().exists()).toBe(false);
    });
  });

  describe('rendering', () => {
    it('renders the series chart with the line variant', () => {
      createComponent({ fields: [DIMENSION, TOTAL_COUNT, ACCEPTANCE_RATE] });

      expect(findSeriesChart().props()).toMatchObject({
        variant: 'line',
        data: DATA,
        dimension: DIMENSION,
        metrics: [TOTAL_COUNT, ACCEPTANCE_RATE],
      });
    });
  });

  describe('validation wiring', () => {
    it('emits the single-dimension error when there are more than 1 dimension', () => {
      createComponent({
        fields: [
          { key: 'a', label: 'A', name: 'a', type: 'dimension' },
          { key: 'b', label: 'B', name: 'b', type: 'dimension' },
          { key: 'm', label: 'M', name: 'm', type: 'metric' },
        ],
      });

      expect(wrapper.emitted('error')?.[0]?.[0]?.message).toBe(
        'lineChart supports exactly one dimension',
      );
      expect(findSeriesChart().exists()).toBe(false);
    });
  });
});
