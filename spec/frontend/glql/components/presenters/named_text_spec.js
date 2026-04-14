import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NamedTextPresenter from '~/glql/components/presenters/named_text.vue';
import { MOCK_CI_STAGE } from '../../mock_data';

describe('NamedTextPresenter', () => {
  it('renders the name property of the data object', () => {
    const wrapper = shallowMountExtended(NamedTextPresenter, {
      propsData: { data: MOCK_CI_STAGE },
    });

    expect(wrapper.text()).toBe('test');
  });
});
