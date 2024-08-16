import { mountExtended } from 'helpers/vue_test_utils_helper';
import BoolPresenter from '~/glql/components/presenters/bool.vue';
import HealthPresenter from '~/glql/components/presenters/health.vue';
import LinkPresenter from '~/glql/components/presenters/link.vue';
import ListPresenter from '~/glql/components/presenters/list.vue';
import StatePresenter from '~/glql/components/presenters/state.vue';
import TablePresenter from '~/glql/components/presenters/table.vue';
import TextPresenter from '~/glql/components/presenters/text.vue';
import TimePresenter from '~/glql/components/presenters/time.vue';
import Presenter, { componentForField } from '~/glql/core/presenter';
import { MOCK_FIELDS, MOCK_ISSUES } from '../mock_data';

describe('componentForField', () => {
  it.each`
    dataType     | field                                | presenter        | presenterName
    ${'string'}  | ${'text'}                            | ${TextPresenter} | ${'TextPresenter'}
    ${'number'}  | ${100}                               | ${TextPresenter} | ${'TextPresenter'}
    ${'boolean'} | ${true}                              | ${BoolPresenter} | ${'BoolPresenter'}
    ${'object'}  | ${{ title: 'title', webUrl: 'url' }} | ${LinkPresenter} | ${'LinkPresenter'}
    ${'date'}    | ${'2021-01-01'}                      | ${TimePresenter} | ${'TimePresenter'}
  `('returns $presenterName for data type: $dataType', ({ field, presenter }) => {
    expect(componentForField(field)).toBe(presenter);
  });

  describe('if field name is passed', () => {
    it.each`
      fieldName         | field        | presenter          | presenterName
      ${'healthStatus'} | ${'onTrack'} | ${HealthPresenter} | ${'HealthPresenter'}
      ${'state'}        | ${'opened'}  | ${StatePresenter}  | ${'StatePresenter'}
    `('returns $presenterName for field name: $fieldName', ({ fieldName, field, presenter }) => {
      expect(componentForField(field, fieldName)).toBe(presenter);
    });
  });
});

describe('Presenter', () => {
  it.each`
    displayType      | additionalProps       | PresenterComponent
    ${'list'}        | ${{ listType: 'ul' }} | ${ListPresenter}
    ${'orderedList'} | ${{ listType: 'ol' }} | ${ListPresenter}
    ${'table'}       | ${{}}                 | ${TablePresenter}
  `(
    'inits appropriate presenter component for displayType: $displayType with additionalProps: $additionalProps',
    async ({ displayType, additionalProps, PresenterComponent }) => {
      const element = document.createElement('div');
      element.innerHTML =
        '<pre><code data-canonical-lang="glql">assignee = currentUser()</code></pre>';
      const data = MOCK_ISSUES;
      const config = { display: displayType, fields: MOCK_FIELDS };

      const { component } = await new Presenter().init({ data, config });
      const wrapper = mountExtended(component);
      const presenter = wrapper.findComponent(PresenterComponent);

      expect(presenter.exists()).toBe(true);
      expect(presenter.props('data')).toBe(data);
      expect(presenter.props('config')).toBe(config);
      expect(presenter.props()).toMatchObject(additionalProps);
    },
  );
});
