import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BarChartPresenter from '~/glql/components/presenters/bar_chart.vue';
import ColumnChartPresenter from '~/glql/components/presenters/column_chart.vue';
import LineChartPresenter from '~/glql/components/presenters/line_chart.vue';
import ListPresenter from '~/glql/components/presenters/list.vue';
import StatPresenter from '~/glql/components/presenters/stat.vue';
import TablePresenter from '~/glql/components/presenters/table.vue';
import DataPresenter from '~/glql/components/presenters/data.vue';
import {
  MOCK_FIELDS,
  MOCK_ISSUES,
  MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
  MOCK_AGGREGATED_DATA_ONE_DIM,
} from '../../mock_data';

const MOCK_STAT_FIELDS = [
  { key: 'totalCount', label: 'Total count', name: 'totalCount', type: 'metric' },
];

describe('DataPresenter', () => {
  it.each`
    displayType      | fields                                       | presenterProps                                           | PresenterComponent
    ${'list'}        | ${MOCK_FIELDS}                               | ${{ fields: MOCK_FIELDS, listType: 'ul' }}               | ${ListPresenter}
    ${'orderedList'} | ${MOCK_FIELDS}                               | ${{ fields: MOCK_FIELDS, listType: 'ol' }}               | ${ListPresenter}
    ${'table'}       | ${MOCK_FIELDS}                               | ${{ fields: MOCK_FIELDS }}                               | ${TablePresenter}
    ${'stat'}        | ${MOCK_STAT_FIELDS}                          | ${{ fields: MOCK_STAT_FIELDS }}                          | ${StatPresenter}
    ${'columnChart'} | ${MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC} | ${{ fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC }} | ${ColumnChartPresenter}
    ${'lineChart'}   | ${MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC} | ${{ fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC }} | ${LineChartPresenter}
    ${'barChart'}    | ${MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC} | ${{ fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC }} | ${BarChartPresenter}
  `(
    'inits appropriate presenter for displayType: $displayType',
    ({ displayType, fields, presenterProps, PresenterComponent }) => {
      const data = MOCK_ISSUES;

      const wrapper = shallowMountExtended(DataPresenter, {
        propsData: { data, displayType, fields },
      });

      const presenter = wrapper.findComponent(PresenterComponent);

      expect(presenter.props('data')).toBe(data);
      expect(presenter.props('loading')).toBe(false);

      for (const [key, value] of Object.entries(presenterProps)) {
        expect(presenter.props(key)).toBe(value);
      }
    },
  );

  describe('columnChart', () => {
    it('forwards displayConfig to the column chart presenter', () => {
      const displayConfig = { stacked: true };

      const wrapper = shallowMountExtended(DataPresenter, {
        propsData: {
          data: MOCK_AGGREGATED_DATA_ONE_DIM,
          displayType: 'columnChart',
          fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
          displayConfig,
        },
      });

      expect(wrapper.findComponent(ColumnChartPresenter).props('displayConfig')).toBe(
        displayConfig,
      );
    });

    it('re-emits errors from the column chart presenter', () => {
      const wrapper = shallowMountExtended(DataPresenter, {
        propsData: {
          data: MOCK_AGGREGATED_DATA_ONE_DIM,
          displayType: 'columnChart',
          fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
        },
      });

      const error = new Error('boom');
      wrapper.findComponent(ColumnChartPresenter).vm.$emit('error', error);

      expect(wrapper.emitted('error')).toEqual([[error]]);
    });
  });

  describe('barChart', () => {
    it('forwards displayConfig to the bar chart presenter', () => {
      const displayConfig = { stacked: true };

      const wrapper = shallowMountExtended(DataPresenter, {
        propsData: {
          data: MOCK_AGGREGATED_DATA_ONE_DIM,
          displayType: 'barChart',
          fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
          displayConfig,
        },
      });

      expect(wrapper.findComponent(BarChartPresenter).props('displayConfig')).toBe(displayConfig);
    });

    it('re-emits errors from the bar chart presenter', () => {
      const wrapper = shallowMountExtended(DataPresenter, {
        propsData: {
          data: MOCK_AGGREGATED_DATA_ONE_DIM,
          displayType: 'barChart',
          fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
        },
      });

      const error = new Error('boom');
      wrapper.findComponent(BarChartPresenter).vm.$emit('error', error);

      expect(wrapper.emitted('error')).toEqual([[error]]);
    });
  });

  describe('stat', () => {
    it('re-emits errors from the stat presenter', () => {
      const wrapper = shallowMountExtended(DataPresenter, {
        propsData: {
          data: MOCK_AGGREGATED_DATA_ONE_DIM,
          displayType: 'stat',
          fields: MOCK_STAT_FIELDS,
        },
      });

      const error = new Error('boom');
      wrapper.findComponent(StatPresenter).vm.$emit('error', error);

      expect(wrapper.emitted('error')).toEqual([[error]]);
    });
  });

  describe('lineChart', () => {
    it('re-emits errors from the line chart presenter', () => {
      const wrapper = shallowMountExtended(DataPresenter, {
        propsData: {
          data: MOCK_AGGREGATED_DATA_ONE_DIM,
          displayType: 'lineChart',
          fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
        },
      });

      const error = new Error('boom');
      wrapper.findComponent(LineChartPresenter).vm.$emit('error', error);

      expect(wrapper.emitted('error')).toEqual([[error]]);
    });
  });

  describe('unsupported display type', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = shallowMountExtended(DataPresenter, {
        propsData: { data: MOCK_ISSUES, displayType: 'pieChart', fields: MOCK_FIELDS },
      });
    });

    it('emits an error listing the supported display types', () => {
      const [[error]] = wrapper.emitted('error');

      expect(error).toEqual(expect.any(Error));
      expect(error.message).toBe(
        'Unknown display type: `pieChart`. Supported display types are: ' +
          '`list`, `orderedList`, `table`, `stat`, `columnChart`, `lineChart`, `barChart`.',
      );
    });

    it('does not render any presenter', () => {
      expect(wrapper.findComponent(ListPresenter).exists()).toBe(false);
      expect(wrapper.findComponent(TablePresenter).exists()).toBe(false);
      expect(wrapper.findComponent(StatPresenter).exists()).toBe(false);
      expect(wrapper.findComponent(ColumnChartPresenter).exists()).toBe(false);
      expect(wrapper.findComponent(LineChartPresenter).exists()).toBe(false);
      expect(wrapper.findComponent(BarChartPresenter).exists()).toBe(false);
    });
  });
});
