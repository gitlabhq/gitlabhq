import Presenter, { componentForField } from '~/glql/core/presenter';
import LinkPresenter from '~/glql/components/presenters/link.vue';
import TextPresenter from '~/glql/components/presenters/text.vue';
import ListPresenter from '~/glql/components/presenters/list.vue';
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
    displayType      | additionalProps
    ${'list'}        | ${{ listType: 'ul' }}
    ${'orderedList'} | ${{ listType: 'ol' }}
  `(
    'inits a ListPresenter for displayType: $displayType with additionalProps: $additionalProps',
    async ({ displayType, additionalProps }) => {
      const element = document.createElement('div');
      element.innerHTML =
        '<pre><code data-canonical-lang="glql">assignee = currentUser()</code></pre>';
      const data = MOCK_ISSUES;
      const config = { display: displayType, fields: MOCK_FIELDS };

      const { component } = await new Presenter().init({ data, config });
      const wrapper = mountExtended(component);
      const listPresenter = wrapper.findComponent(ListPresenter);

      expect(listPresenter.exists()).toBe(true);
      expect(listPresenter.props('data')).toBe(data);
      expect(listPresenter.props('config')).toBe(config);
      expect(listPresenter.props()).toMatchObject(additionalProps);
    },
  );
});
