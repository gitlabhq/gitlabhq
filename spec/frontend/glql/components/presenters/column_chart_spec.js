import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ColumnChartPresenter from '~/glql/components/presenters/column_chart.vue';
import SingleDimensionColumnChart from '~/glql/components/presenters/column_chart/single_dimension_column_chart.vue';
import TwoDimensionsColumnChart from '~/glql/components/presenters/column_chart/two_dimensions_column_chart.vue';
import {
  MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
  MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS,
  MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
  MOCK_AGGREGATED_DATA_ONE_DIM,
  MOCK_AGGREGATED_DATA_TWO_DIMS,
} from '../../mock_data';

describe('ColumnChartPresenter', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ColumnChartPresenter, {
      propsData: {
        data: MOCK_AGGREGATED_DATA_ONE_DIM,
        fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
        ...props,
      },
    });
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findSingleDim = () => wrapper.findComponent(SingleDimensionColumnChart);
  const findTwoDim = () => wrapper.findComponent(TwoDimensionsColumnChart);

  describe('loading state', () => {
    beforeEach(() => {
      createComponent({ loading: true });
    });

    it('renders the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('does not render any chart', () => {
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

    it('routes to the two-dimension chart for 2 dimensions', () => {
      createComponent({
        fields: MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
        data: MOCK_AGGREGATED_DATA_TWO_DIMS,
      });

      expect(findTwoDim().exists()).toBe(true);
      expect(findSingleDim().exists()).toBe(false);
    });

    it('ignores displayConfig.stacked with 2 dimensions', () => {
      createComponent({
        fields: MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
        data: MOCK_AGGREGATED_DATA_TWO_DIMS,
        displayConfig: { stacked: true },
      });

      expect(findTwoDim().exists()).toBe(true);
      expect(findSingleDim().exists()).toBe(false);
    });
  });

  describe('validation', () => {
    const findEmittedErrorMessage = () => wrapper.emitted('error')?.[0]?.[0]?.message;

    it('emits error when there are no dimensions', () => {
      createComponent({
        fields: [{ key: 'totalCount', label: 'Total count', name: 'totalCount', type: 'metric' }],
      });

      expect(findEmittedErrorMessage()).toBe('columnChart requires at least one dimension');
      expect(findSingleDim().exists()).toBe(false);
      expect(findTwoDim().exists()).toBe(false);
    });

    it('emits error when there are more than 2 dimensions', () => {
      createComponent({
        fields: [
          { key: 'a', label: 'A', name: 'a', type: 'dimension' },
          { key: 'b', label: 'B', name: 'b', type: 'dimension' },
          { key: 'c', label: 'C', name: 'c', type: 'dimension' },
          { key: 'm', label: 'M', name: 'm', type: 'metric' },
        ],
      });

      expect(findEmittedErrorMessage()).toBe('columnChart supports a maximum of 2 dimensions');
    });

    it('emits error when there are no metrics', () => {
      createComponent({
        fields: [{ key: 'language', label: 'Language', name: 'language', type: 'dimension' }],
      });

      expect(findEmittedErrorMessage()).toBe('columnChart requires at least one metric');
    });

    it('emits error when there are 2 dimensions and more than one metric', () => {
      createComponent({
        fields: [
          { key: 'user', label: 'User', name: 'user', type: 'dimension' },
          { key: 'language', label: 'Language', name: 'language', type: 'dimension' },
          { key: 'totalCount', label: 'Total count', name: 'totalCount', type: 'metric' },
          {
            key: 'acceptanceRate',
            label: 'Acceptance rate',
            name: 'acceptanceRate',
            type: 'metric',
          },
        ],
      });

      expect(findEmittedErrorMessage()).toBe(
        'columnChart with 2 dimensions supports only a single metric',
      );
    });

    it('does not emit error before fields are populated', () => {
      createComponent({ fields: [] });

      expect(wrapper.emitted('error')).toBeUndefined();
    });
  });
});
