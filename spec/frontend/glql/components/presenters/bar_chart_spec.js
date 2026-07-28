import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BarChartPresenter from '~/glql/components/presenters/bar_chart.vue';
import DimensionRoutedChart from '~/glql/components/presenters/chart/dimension_routed_chart.vue';
import SingleDimensionBarChart from '~/glql/components/presenters/bar_chart/single_dimension_bar_chart.vue';
import TwoDimensionsBarChart from '~/glql/components/presenters/bar_chart/two_dimensions_bar_chart.vue';
import {
  MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
  MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS,
  MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
  MOCK_AGGREGATED_DATA_ONE_DIM,
  MOCK_AGGREGATED_DATA_TWO_DIMS,
} from '../../mock_data';

describe('BarChartPresenter', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(BarChartPresenter, {
      propsData: {
        data: MOCK_AGGREGATED_DATA_ONE_DIM,
        fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
        ...props,
      },
      // Render the real routing shell (validation/loading covered in
      // dimension_routed_chart_spec.js) while its chart children stay stubbed.
      stubs: { DimensionRoutedChart },
    });
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findSingleDim = () => wrapper.findComponent(SingleDimensionBarChart);
  const findTwoDim = () => wrapper.findComponent(TwoDimensionsBarChart);

  describe('loading state', () => {
    it('renders the skeleton loader and no chart while loading', () => {
      createComponent({ loading: true });

      expect(findSkeletonLoader().exists()).toBe(true);
      expect(findSingleDim().exists()).toBe(false);
      expect(findTwoDim().exists()).toBe(false);
    });
  });

  describe('routing', () => {
    it('routes to the single-dimension chart for 1 dimension', () => {
      createComponent();

      expect(findSingleDim().exists()).toBe(true);
      expect(findTwoDim().exists()).toBe(false);
    });

    it('forwards the dimension and metrics to the single-dimension chart', () => {
      createComponent({ fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS });

      const [dimension] = MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS.filter(
        (f) => f.type === 'dimension',
      );
      const metrics = MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS.filter((f) => f.type === 'metric');

      expect(findSingleDim().props()).toMatchObject({
        data: MOCK_AGGREGATED_DATA_ONE_DIM,
        dimension,
        metrics,
        stacked: false,
      });
    });

    it('forwards stacked=true when displayConfig.stacked is set', () => {
      createComponent({
        fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS,
        displayConfig: { stacked: true },
      });

      expect(findSingleDim().props('stacked')).toBe(true);
    });

    it('routes to the two-dimension chart for 2 dimensions, ignoring displayConfig.stacked', () => {
      createComponent({
        fields: MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
        data: MOCK_AGGREGATED_DATA_TWO_DIMS,
        displayConfig: { stacked: true },
      });

      expect(findTwoDim().exists()).toBe(true);
      expect(findSingleDim().exists()).toBe(false);
    });

    it('forwards both dimensions and the metric to the two-dimension chart', () => {
      createComponent({
        fields: MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
        data: MOCK_AGGREGATED_DATA_TWO_DIMS,
      });

      const [primaryDimension, secondaryDimension] =
        MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC.filter((f) => f.type === 'dimension');
      const [metric] = MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC.filter(
        (f) => f.type === 'metric',
      );

      expect(findTwoDim().props()).toMatchObject({
        data: MOCK_AGGREGATED_DATA_TWO_DIMS,
        primaryDimension,
        secondaryDimension,
        metric,
      });
    });
  });

  describe('validation wiring', () => {
    it('emits errors naming the display type', () => {
      createComponent({
        fields: [{ key: 'totalCount', label: 'Total count', name: 'totalCount', type: 'metric' }],
      });

      expect(wrapper.emitted('error')?.[0]?.[0]?.message).toBe(
        'barChart requires at least one dimension',
      );
      expect(findSingleDim().exists()).toBe(false);
      expect(findTwoDim().exists()).toBe(false);
    });
  });
});
