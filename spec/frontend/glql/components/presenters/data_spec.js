import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ColumnChartPresenter from '~/glql/components/presenters/column_chart.vue';
import ListPresenter from '~/glql/components/presenters/list.vue';
import TablePresenter from '~/glql/components/presenters/table.vue';
import DataPresenter from '~/glql/components/presenters/data.vue';
import {
  MOCK_FIELDS,
  MOCK_ISSUES,
  MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
  MOCK_AGGREGATED_DATA_ONE_DIM,
} from '../../mock_data';

describe('DataPresenter', () => {
  it.each`
    displayType      | fields                                       | presenterProps                                           | PresenterComponent
    ${'list'}        | ${MOCK_FIELDS}                               | ${{ fields: MOCK_FIELDS, listType: 'ul' }}               | ${ListPresenter}
    ${'orderedList'} | ${MOCK_FIELDS}                               | ${{ fields: MOCK_FIELDS, listType: 'ol' }}               | ${ListPresenter}
    ${'table'}       | ${MOCK_FIELDS}                               | ${{ fields: MOCK_FIELDS }}                               | ${TablePresenter}
    ${'columnChart'} | ${MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC} | ${{ fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC }} | ${ColumnChartPresenter}
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
});
