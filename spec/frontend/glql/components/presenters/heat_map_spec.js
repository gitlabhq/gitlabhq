import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HeatMapChart from '~/analytics/analytics_dashboards/components/visualizations/heat_map_chart.vue';
import HeatMapPresenter from '~/glql/components/presenters/heat_map.vue';
import DimensionRoutedChart from '~/glql/components/presenters/chart/dimension_routed_chart.vue';
import {
  MOCK_AGGREGATED_DATA_TWO_DIMS,
  MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
  MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
  MOCK_AGGREGATED_FIELDS_TWO_DIMS_TWO_METRICS,
} from '../../mock_data';

describe('HeatMapPresenter', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(HeatMapPresenter, {
      propsData: {
        data: MOCK_AGGREGATED_DATA_TWO_DIMS,
        fields: MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
        ...props,
      },
      stubs: { DimensionRoutedChart },
    });
  };

  const findChart = () => wrapper.findComponent(HeatMapChart);

  beforeEach(() => {
    createComponent();
  });

  it('renders the heat map chart', () => {
    expect(findChart().exists()).toBe(true);
  });

  it('turns the aggregated rows into cells, first dimension across the columns', () => {
    expect(findChart().props('data')).toEqual([
      { column: 'user-0', row: 'ruby', value: 12 },
      { column: 'user-2', row: 'ruby', value: 6 },
      { column: 'user-0', row: 'python', value: 6 },
      { column: 'user-2', row: 'python', value: 5 },
    ]);
  });

  it('formats the in-cell value with the metric unit, compactly', () => {
    expect(findChart().props('options').formatValue(2500000)).toBe('2.5M');
  });

  it('describes the chart for assistive technology', () => {
    expect(findChart().props('options').aria.label.description).toBe(
      'Heat map of Total count by User and Language.',
    );
  });

  describe('validation', () => {
    it.each`
      scenario              | fields                                                                                                                       | message
      ${'one dimension'}    | ${MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC}                                                                                 | ${'heatMap requires 2 dimensions'}
      ${'two metrics'}      | ${MOCK_AGGREGATED_FIELDS_TWO_DIMS_TWO_METRICS}                                                                               | ${'heatMap with 2 dimensions supports only a single metric'}
      ${'no dimensions'}    | ${[{ key: 'totalCount', label: 'Total count', name: 'totalCount', type: 'metric' }]}                                         | ${'heatMap requires 2 dimensions'}
      ${'three dimensions'} | ${[...MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC, { key: 'project', label: 'Project', name: 'project', type: 'dimension' }]} | ${'heatMap supports a maximum of 2 dimensions'}
    `('emits an error and renders nothing for $scenario', ({ fields, message }) => {
      createComponent({ fields });

      expect(wrapper.emitted('error')[0][0].message).toBe(message);
      expect(findChart().exists()).toBe(false);
    });
  });

  describe('description', () => {
    it('renders no description by default', () => {
      expect(wrapper.find('p').exists()).toBe(false);
    });

    it('renders the description from displayConfig', () => {
      createComponent({ displayConfig: { description: 'Sessions per capability by tier' } });

      expect(wrapper.find('p').text()).toBe('Sessions per capability by tier');
    });
  });

  it('names the metric in the tooltip, so a query alias can say "Sessions"', () => {
    const aliased = mountExtended(HeatMapPresenter, {
      propsData: {
        data: { nodes: [{ user: 'user-0', language: 'ruby', totalCount: 12345 }] },
        fields: [
          ...MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC.filter((f) => f.type === 'dimension'),
          { key: 'totalCount', field: 'totalCount', label: 'Sessions', type: 'metric' },
        ],
      },
      stubs: {
        HeatMapChart: {
          props: ['options'],
          template: '<div><slot name="tooltip-content" :value="12345"></slot></div>',
        },
      },
    });

    expect(aliased.text()).toContain('Sessions');
    expect(aliased.text()).toContain('12,345');
  });

  it('formats the tooltip value with full digits, unlike the cell', () => {
    const mounted = mountExtended(HeatMapPresenter, {
      propsData: {
        data: {
          nodes: [{ user: 'user-0', language: 'ruby', totalCount: 12345 }],
        },
        fields: MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
      },
      stubs: {
        HeatMapChart: {
          props: ['options'],
          template: '<div><slot name="tooltip-content" :value="12345"></slot></div>',
        },
      },
    });

    expect(mounted.text()).toContain('Total count');
    expect(mounted.text()).toContain('12,345');
  });
});
