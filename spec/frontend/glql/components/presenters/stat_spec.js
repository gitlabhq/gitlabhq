import { GlSingleStat } from '@gitlab/ui/src/charts';
import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import StatPresenter from '~/glql/components/presenters/stat.vue';

const TOTAL_COUNT = {
  key: 'totalCount',
  label: 'Total Suggestions',
  name: 'totalCount',
  type: 'metric',
};
const ACCEPTANCE_RATE = {
  key: 'acceptanceRate',
  label: 'Acceptance Rate',
  name: 'acceptanceRate',
  type: 'metric',
};
const USERS_COUNT = {
  key: 'usersCount',
  label: 'Total unique users',
  name: 'usersCount',
  type: 'metric',
};
const DURATION_QUANTILE = {
  key: 'durationQuantile',
  label: 'p95',
  name: 'durationQuantile',
  type: 'metric',
};
const DIMENSION = { key: 'language', label: 'Language', name: 'language', type: 'dimension' };

const DATA = {
  nodes: [
    {
      totalCount: 1234,
      acceptanceRate: 0.735,
      usersCount: 14614,
      durationQuantile: 3661,
    },
  ],
};

describe('StatPresenter', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(StatPresenter, {
      propsData: {
        data: DATA,
        fields: [TOTAL_COUNT],
        ...props,
      },
    });
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findSingleStat = () => wrapper.findComponent(GlSingleStat);
  const findEmittedErrorMessage = () => wrapper.emitted('error')?.[0]?.[0]?.message;

  describe('loading state', () => {
    beforeEach(() => {
      createComponent({ loading: true });
    });

    it('renders the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('does not render the stat', () => {
      expect(findSingleStat().exists()).toBe(false);
    });
  });

  describe('rendering', () => {
    it('renders GlSingleStat with only the value, leaving the title to the container', () => {
      createComponent();

      expect(findSingleStat().exists()).toBe(true);
      expect(findSingleStat().props('title')).toBe('');
    });

    it.each`
      field                | expectedValue
      ${TOTAL_COUNT}       | ${'1,234'}
      ${ACCEPTANCE_RATE}   | ${'73.5%'}
      ${USERS_COUNT}       | ${'14,614'}
      ${DURATION_QUANTILE} | ${'1h 1m 1s'}
    `('formats the value of $field.key as $expectedValue', ({ field, expectedValue }) => {
      createComponent({ fields: [field] });

      expect(findSingleStat().props('value')).toBe(expectedValue);
    });

    it('renders the raw value for a metric with no registered unit', () => {
      const custom = {
        key: 'somethingCustom',
        label: 'Custom',
        name: 'somethingCustom',
        type: 'metric',
      };
      createComponent({ fields: [custom], data: { nodes: [{ somethingCustom: 1234 }] } });

      expect(findSingleStat().props('value')).toBe('1234');
    });

    it('renders a placeholder when the aggregation returns no node', () => {
      createComponent({ data: { nodes: [] } });

      expect(findSingleStat().props('value')).toBe('—');
    });

    it('renders a placeholder when the metric value is null', () => {
      createComponent({ data: { nodes: [{ totalCount: null }] } });

      expect(findSingleStat().props('value')).toBe('—');
    });

    it('renders a real zero value rather than the no-data placeholder', () => {
      createComponent({ data: { nodes: [{ totalCount: 0 }] } });

      expect(findSingleStat().props('value')).toBe('0');
    });
  });

  describe('validation', () => {
    it('emits an error when there are no metrics', () => {
      createComponent({ fields: [DIMENSION] });

      expect(findEmittedErrorMessage()).toBe('stat display type requires exactly 1 metric');
      expect(findSingleStat().exists()).toBe(false);
    });

    it('emits an error when there is more than one metric', () => {
      createComponent({ fields: [TOTAL_COUNT, ACCEPTANCE_RATE] });

      expect(findEmittedErrorMessage()).toBe('stat display type requires exactly 1 metric');
      expect(findSingleStat().exists()).toBe(false);
    });

    it('emits an error when dimensions are present', () => {
      createComponent({ fields: [DIMENSION, TOTAL_COUNT] });

      expect(findEmittedErrorMessage()).toBe('stat display type cannot have dimensions');
      expect(findSingleStat().exists()).toBe(false);
    });

    it('does not emit an error and does not render the stat before fields are populated', () => {
      createComponent({ fields: [] });

      expect(wrapper.emitted('error')).toBeUndefined();
      expect(findSingleStat().exists()).toBe(false);
    });
  });
});
