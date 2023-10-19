import { mount } from '@vue/test-utils';
import { GlBadge } from '@gitlab/ui';
import BetaBadge from '~/vue_shared/components/badges/beta_badge.vue';

describe('Beta badge component', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);
  const createWrapper = (props = {}) => {
    wrapper = mount(BetaBadge, {
      propsData: { ...props },
    });
  };

  it('renders the badge', () => {
    createWrapper();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('passes default size to badge', () => {
    createWrapper();

    expect(findBadge().props('size')).toBe('md');
  });

  it('passes given size to badge', () => {
    createWrapper({ size: 'sm' });

    expect(findBadge().props('size')).toBe('sm');
  });
});
