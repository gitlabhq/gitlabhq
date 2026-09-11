import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DivergingBarChartPresenter from '~/glql/components/presenters/diverging_bar_chart.vue';
import DivergingBarChart from '~/analytics/analytics_dashboards/components/visualizations/diverging_bar_chart.vue';
import {
  MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
  MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS,
  MOCK_AGGREGATED_FIELDS_TWO_DIMS_TWO_METRICS,
  MOCK_AGGREGATED_DATA_ONE_DIM,
} from '../../mock_data';

describe('DivergingBarChartPresenter', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const findChart = () => wrapper.findComponent(DivergingBarChart);
  const findSkeleton = () => wrapper.findComponent(GlSkeletonLoader);
  const errorMessages = () => (wrapper.emitted('error') ?? []).map(([error]) => error.message);

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(DivergingBarChartPresenter, {
      propsData: {
        data: MOCK_AGGREGATED_DATA_ONE_DIM,
        fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS,
        ...props,
      },
    });
  };

  describe('default', () => {
    beforeEach(() => createWrapper());

    it('renders the chart', () => {
      expect(findChart().exists()).toBe(true);
    });

    it('emits no error', () => {
      expect(wrapper.emitted('error')).toBeUndefined();
    });

    it('builds one row per node, in query order', () => {
      expect(findChart().props('data')).toEqual([
        { name: 'ruby', values: [21, 0.625] },
        { name: 'python', values: [14, 0.333] },
        { name: 'go', values: [10, 0.2] },
      ]);
    });

    it('names the series after the metrics', () => {
      expect(findChart().props('seriesNames')).toEqual(['Total count', 'Acceptance rate']);
    });

    // A rate and a count in the same chart must not both render as plain
    // numbers, so each series carries its own unit-aware formatter.
    it('formats each series in its own unit', () => {
      const [formatCount, formatRate] = findChart().props('valueFormatters');

      expect(formatCount(2570)).toBe('2.6k');
      expect(formatRate(0.625)).toBe('62.5%');
    });
  });

  describe('when loading', () => {
    beforeEach(() => createWrapper({ loading: true }));

    it('renders a skeleton instead of the chart', () => {
      expect(findSkeleton().exists()).toBe(true);
      expect(findChart().exists()).toBe(false);
    });
  });

  describe('when a metric is missing from a node', () => {
    beforeEach(() => createWrapper({ data: { nodes: [{ language: 'ruby', totalCount: 21 }] } }));

    it('plots the gap as zero', () => {
      expect(findChart().props('data')).toEqual([{ name: 'ruby', values: [21, 0] }]);
    });
  });

  // dimensionLabelFormatter turns a raw bucket start into a readable range, so
  // a date dimension must not render as an ISO string.
  describe('with a date bucket dimension', () => {
    beforeEach(() =>
      createWrapper({
        fields: [
          {
            key: 'created',
            label: 'Created',
            name: 'created',
            type: 'dimension',
            parameters: { granularity: 'monthly' },
          },
          { key: 'usersCount', label: 'Users', name: 'usersCount', type: 'metric' },
          { key: 'totalCount', label: 'Sessions', name: 'totalCount', type: 'metric' },
        ],
        data: {
          nodes: [
            { created: '2026-07-01', usersCount: 10, totalCount: 90 },
            { created: '2026-08-01', usersCount: 20, totalCount: 80 },
          ],
        },
      }),
    );

    it('formats the bucket start rather than showing the raw date', () => {
      expect(
        findChart()
          .props('data')
          .map(({ name }) => name),
      ).toEqual(['Jul 2026', 'Aug 2026']);
    });
  });

  describe('validation', () => {
    it('rejects a single metric', () => {
      createWrapper({ fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC });

      expect(errorMessages()).toEqual([
        'divergingBarChart display type requires exactly 2 metrics',
      ]);
      expect(findChart().exists()).toBe(false);
    });

    it('rejects two dimensions', () => {
      createWrapper({ fields: MOCK_AGGREGATED_FIELDS_TWO_DIMS_TWO_METRICS });

      expect(errorMessages()).toEqual([
        'divergingBarChart display type requires exactly 1 dimension',
      ]);
      expect(findChart().exists()).toBe(false);
    });

    it('rejects no dimensions', () => {
      createWrapper({
        fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS.filter(
          ({ type }) => type !== 'dimension',
        ),
      });

      expect(errorMessages()).toEqual([
        'divergingBarChart display type requires exactly 1 dimension',
      ]);
    });

    // An empty field set is not an error, but it is not a chart either.
    it('draws nothing before the fields arrive', () => {
      createWrapper({ fields: [] });

      expect(findChart().exists()).toBe(false);
      expect(wrapper.emitted('error')).toBeUndefined();
    });
  });
});
