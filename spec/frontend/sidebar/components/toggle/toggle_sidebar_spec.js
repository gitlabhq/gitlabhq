import { GlButton } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';

import { nextTick } from 'vue';
import ToggleSidebar from '~/sidebar/components/toggle/toggle_sidebar.vue';

describe('ToggleSidebar', () => {
  let wrapper;

  const defaultProps = {
    collapsed: true,
  };

  const createComponent = ({ mountFn = shallowMount, props = {} } = {}) => {
    wrapper = mountFn(ToggleSidebar, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findGlButton = () => wrapper.findComponent(GlButton);

  it('should render the "chevron-double-lg-left" icon when collapsed', () => {
    createComponent();

    expect(findGlButton().props('icon')).toBe('chevron-double-lg-left');
  });

  it('should render the "chevron-double-lg-right" icon when expanded', () => {
    createComponent({ props: { collapsed: false } });

    expect(findGlButton().props('icon')).toBe('chevron-double-lg-right');
  });

  it('should emit toggle event when button clicked', async () => {
    createComponent({ mountFn: mount });

    findGlButton().trigger('click');
    await nextTick();

    expect(wrapper.emitted('toggle')[0]).toBeDefined();
  });
});
