import { mount } from '@vue/test-utils';
import BetaBadge from '~/vue_shared/components/badges/beta_badge.vue';

describe('Beta badge component', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = mount(BetaBadge, {
      propsData: { ...props },
    });
  };

  it('renders the badge', () => {
    createWrapper();

    expect(wrapper.element).toMatchSnapshot();
  });
});
