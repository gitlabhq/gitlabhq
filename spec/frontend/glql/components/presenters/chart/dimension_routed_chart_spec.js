import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DimensionRoutedChart from '~/glql/components/presenters/chart/dimension_routed_chart.vue';

const DIM_A = { key: 'a', label: 'A', name: 'a', type: 'dimension' };
const DIM_B = { key: 'b', label: 'B', name: 'b', type: 'dimension' };
const DIM_C = { key: 'c', label: 'C', name: 'c', type: 'dimension' };
const METRIC_X = { key: 'x', label: 'X', name: 'x', type: 'metric' };
const METRIC_Y = { key: 'y', label: 'Y', name: 'y', type: 'metric' };

describe('DimensionRoutedChart', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(DimensionRoutedChart, {
      propsData: {
        displayType: 'someChart',
        fields: [DIM_A, METRIC_X],
        ...props,
      },
      scopedSlots: {
        'one-dimension': `
          <div data-testid="one-dimension">
            {{ props.dimension.label }}|{{ props.metrics.map((m) => m.label).join(',') }}
          </div>`,
        'two-dimensions': `
          <div data-testid="two-dimensions">
            {{ props.dimensions.map((d) => d.label).join(',') }}|{{ props.metric.label }}
          </div>`,
      },
    });
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findOneDimensionSlot = () => wrapper.findByTestId('one-dimension');
  const findTwoDimensionsSlot = () => wrapper.findByTestId('two-dimensions');

  describe('loading state', () => {
    beforeEach(() => {
      createComponent({ loading: true });
    });

    it('renders the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('does not render any slot', () => {
      expect(findOneDimensionSlot().exists()).toBe(false);
      expect(findTwoDimensionsSlot().exists()).toBe(false);
    });
  });

  describe('routing', () => {
    it('renders the one-dimension slot for 1 dimension, exposing dimension and metrics', () => {
      createComponent({ fields: [DIM_A, METRIC_X, METRIC_Y] });

      expect(findOneDimensionSlot().text()).toBe('A|X,Y');
      expect(findTwoDimensionsSlot().exists()).toBe(false);
    });

    it('renders the two-dimensions slot for 2 dimensions, exposing dimensions and the metric', () => {
      createComponent({ fields: [DIM_A, DIM_B, METRIC_X] });

      expect(findTwoDimensionsSlot().text()).toBe('A,B|X');
      expect(findOneDimensionSlot().exists()).toBe(false);
    });
  });

  describe('validation', () => {
    const findEmittedErrorMessage = () => wrapper.emitted('error')?.[0]?.[0]?.message;

    it('emits error and renders no slot when there are no dimensions', () => {
      createComponent({ fields: [METRIC_X] });

      expect(findEmittedErrorMessage()).toBe('someChart requires at least one dimension');
      expect(findOneDimensionSlot().exists()).toBe(false);
      expect(findTwoDimensionsSlot().exists()).toBe(false);
    });

    it('emits error when there are more than maxDimensions dimensions', () => {
      createComponent({ fields: [DIM_A, DIM_B, DIM_C, METRIC_X] });

      expect(findEmittedErrorMessage()).toBe('someChart supports a maximum of 2 dimensions');
    });

    it('emits the singular message when maxDimensions is 1', () => {
      createComponent({ fields: [DIM_A, DIM_B, METRIC_X], maxDimensions: 1 });

      expect(findEmittedErrorMessage()).toBe('someChart supports exactly one dimension');
      expect(findTwoDimensionsSlot().exists()).toBe(false);
    });

    it('emits error when there are no metrics', () => {
      createComponent({ fields: [DIM_A] });

      expect(findEmittedErrorMessage()).toBe('someChart requires at least one metric');
    });

    it('emits error when there are 2 dimensions and more than one metric', () => {
      createComponent({ fields: [DIM_A, DIM_B, METRIC_X, METRIC_Y] });

      expect(findEmittedErrorMessage()).toBe(
        'someChart with 2 dimensions supports only a single metric',
      );
    });

    it('does not emit error and renders no slot before fields are populated', () => {
      createComponent({ fields: [] });

      expect(wrapper.emitted('error')).toBeUndefined();
      expect(findOneDimensionSlot().exists()).toBe(false);
      expect(findTwoDimensionsSlot().exists()).toBe(false);
    });
  });
});
