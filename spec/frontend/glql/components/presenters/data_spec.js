import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ListPresenter from '~/glql/components/presenters/list.vue';
import TablePresenter from '~/glql/components/presenters/table.vue';
import DataPresenter from '~/glql/components/presenters/data.vue';
import { MOCK_FIELDS, MOCK_ISSUES } from '../../mock_data';

describe('DataPresenter', () => {
  it.each`
    displayType      | presenterProps                             | PresenterComponent
    ${'list'}        | ${{ fields: MOCK_FIELDS, listType: 'ul' }} | ${ListPresenter}
    ${'orderedList'} | ${{ fields: MOCK_FIELDS, listType: 'ol' }} | ${ListPresenter}
    ${'table'}       | ${{ fields: MOCK_FIELDS }}                 | ${TablePresenter}
  `(
    'inits appropriate presenter component for displayType: $displayType with presenterProps: $presenterProps',
    ({ displayType, presenterProps, PresenterComponent }) => {
      const data = MOCK_ISSUES;

      const wrapper = shallowMountExtended(DataPresenter, {
        propsData: {
          data,
          displayType,
          fields: MOCK_FIELDS,
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
});
