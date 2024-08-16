import Presenter, { componentForField } from '~/glql/core/presenter';
import LinkPresenter from '~/glql/components/presenters/link.vue';
import TextPresenter from '~/glql/components/presenters/text.vue';
import ListPresenter from '~/glql/components/presenters/list.vue';
import TablePresenter from '~/glql/components/presenters/table.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { MOCK_FIELDS, MOCK_ISSUES } from '../mock_data';

describe('componentForField', () => {
  it.each`
    dataType    | data                                 | presenter        | presenterName
    ${'string'} | ${'text'}                            | ${TextPresenter} | ${'TextPresenter'}
    ${'number'} | ${100}                               | ${TextPresenter} | ${'TextPresenter'}
    ${'object'} | ${{ title: 'title', webUrl: 'url' }} | ${LinkPresenter} | ${'LinkPresenter'}
  `('returns $presenterName for data type: $dataType', ({ data, presenter }) => {
    expect(componentForField(data)).toBe(presenter);
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
