import { mountExtended } from 'helpers/vue_test_utils_helper';
import CollectionPresenter from '~/glql/components/presenters/collection.vue';
import LabelPresenter from '~/glql/components/presenters/label.vue';
import UserPresenter from '~/glql/components/presenters/user.vue';
import Presenter from '~/glql/core/presenter';
import { MOCK_LABELS, MOCK_ASSIGNEES } from '../../mock_data';

describe('CollectionPresenter', () => {
  let wrapper;

  const createWrapper = ({ data }) => {
    wrapper = mountExtended(CollectionPresenter, {
      provide: {
        presenter: new Presenter(),
      },
      propsData: { data },
    });
  };

  it.each`
    name           | mockData          | component         | expectedTexts
    ${'labels'}    | ${MOCK_LABELS}    | ${LabelPresenter} | ${['Label 1', 'Label 2']}
    ${'assignees'} | ${MOCK_ASSIGNEES} | ${UserPresenter}  | ${['@foobar', '@janedoe']}
  `('correctly renders a list of $name', ({ mockData, component, expectedTexts }) => {
    createWrapper({ data: mockData });

    const presenters = wrapper.findAllComponents(component);
    expect(presenters).toHaveLength(2);

    expect(presenters.at(0).props('data')).toBe(mockData.nodes[0]);
    expect(presenters.at(1).props('data')).toBe(mockData.nodes[1]);

    expectedTexts.forEach((text) => {
      expect(wrapper.text()).toContain(text);
    });
  });
});
