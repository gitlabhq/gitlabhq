import { shallowMount } from '@vue/test-utils';
import EditFormButtons from '~/sidebar/components/lock/edit_form_buttons.vue';

describe('EditFormButtons', () => {
  let wrapper;

  const mountComponent = propsData => shallowMount(EditFormButtons, { propsData });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('displays "Unlock" when locked', () => {
    wrapper = mountComponent({
      isLocked: true,
      updateLockedAttribute: () => {},
    });

    expect(wrapper.text()).toContain('Unlock');
  });

  it('displays "Lock" when unlocked', () => {
    wrapper = mountComponent({
      isLocked: false,
      updateLockedAttribute: () => {},
    });

    expect(wrapper.text()).toContain('Lock');
  });
});
