import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LineChartPresenter from '~/glql/components/presenters/line_chart.vue';
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
    });
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findSeriesChart = () => wrapper.findComponent(SingleDimensionSeriesChart);

  describe('loading state', () => {
    beforeEach(() => {
      createComponent({ loading: true });
    });

    it('renders the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('does not render the chart', () => {
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

  describe('validation', () => {
    const findEmittedErrorMessage = () => wrapper.emitted('error')?.[0]?.[0]?.message;

    it('emits error when there are no dimensions', () => {
      createComponent({ fields: [TOTAL_COUNT] });

      expect(findEmittedErrorMessage()).toBe('lineChart requires at least one dimension');
      expect(findSeriesChart().exists()).toBe(false);
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
      expect(findSeriesChart().exists()).toBe(false);
    });

    it('emits error when there are no metrics', () => {
      createComponent({ fields: [DIMENSION] });

      expect(findEmittedErrorMessage()).toBe('lineChart requires at least one metric');
      expect(findSeriesChart().exists()).toBe(false);
    });

    it('does not emit error and does not render chart before fields are populated', () => {
      createComponent({ fields: [] });

      expect(wrapper.emitted('error')).toBeUndefined();
      expect(findSeriesChart().exists()).toBe(false);
    });
  });
});
