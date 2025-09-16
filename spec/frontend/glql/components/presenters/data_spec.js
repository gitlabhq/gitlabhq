import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ListPresenter from '~/glql/components/presenters/list.vue';
import TablePresenter from '~/glql/components/presenters/table.vue';
import ColumnChart from '~/glql/components/presenters/column_chart.vue';
import DataPresenter from '~/glql/components/presenters/data.vue';
import { MOCK_FIELDS, MOCK_ISSUES, MOCK_AGGREGATE, MOCK_GROUP_BY } from '../../mock_data';

describe('DataPresenter', () => {
  it.each`
    displayType      | presenterProps                                           | PresenterComponent
    ${'list'}        | ${{ fields: MOCK_FIELDS, listType: 'ul' }}               | ${ListPresenter}
    ${'orderedList'} | ${{ fields: MOCK_FIELDS, listType: 'ol' }}               | ${ListPresenter}
    ${'table'}       | ${{ fields: MOCK_FIELDS }}                               | ${TablePresenter}
    ${'columnChart'} | ${{ aggregate: MOCK_AGGREGATE, groupBy: MOCK_GROUP_BY }} | ${ColumnChart}
  `(
    'inits appropriate presenter component for displayType: $displayType with presenterProps: $presenterProps',
    ({ displayType, presenterProps, PresenterComponent }) => {
      const data = MOCK_ISSUES;

      const wrapper = shallowMountExtended(DataPresenter, {
        propsData: {
          data,
          displayType,
          fields: MOCK_FIELDS,
          aggregate: MOCK_AGGREGATE,
          groupBy: MOCK_GROUP_BY,
        },
      });

      const presenter = wrapper.findComponent(PresenterComponent);

      expect(presenter.props('data')).toBe(data);
      expect(presenter.props('loading')).toBe(false);

      for (const [key, value] of Object.entries(presenterProps)) {
        expect(presenter.props(key)).toBe(value);
      }
    },
  );

  describe('columnChart error handling', () => {
    const data = MOCK_ISSUES;
    const baseProps = {
      data,
      displayType: 'columnChart',
      fields: MOCK_FIELDS,
    };

    const createWrapper = (overrideProps = {}) => {
      return shallowMountExtended(DataPresenter, {
        propsData: {
          ...baseProps,
          aggregate: MOCK_AGGREGATE,
          groupBy: MOCK_GROUP_BY,
          ...overrideProps,
        },
      });
    };

    it.each`
      scenario                    | props
      ${'without aggregation'}    | ${{ aggregate: null }}
      ${'without groupBy'}        | ${{ groupBy: null }}
      ${'with empty aggregation'} | ${{ aggregate: [] }}
      ${'with empty groupBy'}     | ${{ groupBy: [] }}
    `('emits error when columnChart display type is used $scenario', ({ props }) => {
      const wrapper = createWrapper(props);

      expect(wrapper.emitted('error')).toEqual([
        ['Columns charts require an aggregation to be defined'],
      ]);
    });

    it('does not emit error when columnChart has valid aggregation and groupBy', () => {
      const wrapper = createWrapper();

      expect(wrapper.emitted('error')).toBeUndefined();
    });
  });
});
