import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import CascadingLockIcon from '~/namespaces/cascading_settings/components/cascading_lock_icon.vue';
import LockPopover from '~/namespaces/cascading_settings/components/lock_popover.vue';

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

  const findLockPopover = () => wrapper.findComponent(LockPopover);
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
      ariaLabel: 'Lock popover icon',
    });
  });

  it('does not render LockPopover when targetElement is null', () => {
    wrapper = createComponent();
    expect(findLockPopover().exists()).toBe(false);
  });

  it('renders LockPopover after mounting', async () => {
    wrapper = createComponent();
    await nextTick();
    await nextTick();
    expect(findLockPopover().exists()).toBe(true);
  });

  it('sets targetElement after mounting', async () => {
    wrapper = createComponent();
    await nextTick();
    await nextTick();
    expect(findLockPopover().props().targetElement).not.toBeNull();
  });

  it('passes correct props to LockPopover', async () => {
    const ancestorNamespace = { path: '/test', fullName: 'Test' };
    wrapper = createComponent({
      ancestorNamespace,
      isLockedByApplicationSettings: true,
      isLockedByGroupAncestor: true,
    });

    await nextTick();
    await nextTick();

    expect(findLockPopover().props()).toMatchObject({
      ancestorNamespace,
      isLockedByAdmin: true,
      isLockedByGroupAncestor: true,
    });
  });

  it('validates ancestorNamespace prop', () => {
    const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    const consoleWarnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});

    // Valid prop
    createComponent({ ancestorNamespace: { path: '/test', fullName: 'Test' } });
    expect(consoleErrorSpy).not.toHaveBeenCalled();

    // Invalid prop
    createComponent({ ancestorNamespace: { path: '/test' } });

    const includesValidatorError = (spy) =>
      spy.mock.calls[0]?.[0].includes(
        '[Vue warn]: Invalid prop: custom validator check failed for prop "ancestorNamespace".',
      );

    const failsInVue2 = includesValidatorError(consoleErrorSpy);
    const failsInVue3 = includesValidatorError(consoleWarnSpy);

    expect(failsInVue2 || failsInVue3).toBe(true);

    consoleErrorSpy.mockRestore();
  });
});
