import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContextSwitcherToggle from '~/super_sidebar/components/context_switcher_toggle.vue';

describe('ContextSwitcherToggle component', () => {
  let wrapper;

  const context = {
    id: 1,
    title: 'Title',
    avatar: '/path/to/avatar.png',
  };

  const findGlIcon = () => wrapper.getComponent(GlIcon);

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(ContextSwitcherToggle, {
      propsData: {
        context,
        expanded: false,
        ...props,
      },
    });
  };

  it('renders "chevron-down" icon when not expanded', () => {
    createWrapper();

    expect(findGlIcon().props('name')).toBe('chevron-down');
  });

  it('renders "chevron-up" icon when expanded', () => {
    createWrapper({
      expanded: true,
    });

    expect(findGlIcon().props('name')).toBe('chevron-up');
  });
});
