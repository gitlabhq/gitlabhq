import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import CascadingLockIcon from '~/namespaces/cascading_settings/components/cascading_lock_icon.vue';
import LockTooltip from '~/namespaces/cascading_settings/components/lock_tooltip.vue';

describe('CascadingLockIcon', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    return shallowMount(CascadingLockIcon, {
      propsData: {
        isLockedByApplicationSettings: false,
        isLockedByGroupAncestor: false,
        ...props,
      },
    });
  };

  const findLockTooltip = () => wrapper.findComponent(LockTooltip);
  const findIcon = () => wrapper.findComponent(GlIcon);

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('renders the GlIcon component', () => {
    expect(findIcon().exists()).toBe(true);
  });

  it('sets correct attributes on GlIcon', () => {
    wrapper = createComponent();
    expect(findIcon().props()).toMatchObject({
      name: 'lock',
      ariaLabel: 'Lock tooltip icon',
    });
  });

  it('does not render LockTooltip when targetElement is null', () => {
    wrapper = createComponent();
    expect(findLockTooltip().exists()).toBe(false);
  });

  it('renders LockTooltip after mounting', async () => {
    wrapper = createComponent();
    await nextTick();
    await nextTick();
    expect(findLockTooltip().exists()).toBe(true);
  });

  it('sets targetElement after mounting', async () => {
    wrapper = createComponent();
    await nextTick();
    await nextTick();
    expect(findLockTooltip().props().targetElement).not.toBeNull();
  });

  it('passes correct props to LockTooltip', async () => {
    const ancestorNamespace = { path: '/test', fullName: 'Test' };
    wrapper = createComponent({
      ancestorNamespace,
      isLockedByApplicationSettings: true,
      isLockedByGroupAncestor: true,
    });

    await nextTick();
    await nextTick();

    expect(findLockTooltip().props()).toMatchObject({
      ancestorNamespace,
      isLockedByAdmin: true,
      isLockedByGroupAncestor: true,
    });
  });

  it('validates ancestorNamespace prop', () => {
    const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

    // Valid prop
    createComponent({ ancestorNamespace: { path: '/test', fullName: 'Test' } });
    expect(consoleErrorSpy).not.toHaveBeenCalled();

    // Invalid prop
    createComponent({ ancestorNamespace: { path: '/test' } });
    expect(consoleErrorSpy).toHaveBeenCalled();

    consoleErrorSpy.mockRestore();
  });
});
